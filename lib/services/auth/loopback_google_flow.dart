import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:url_launcher/url_launcher.dart';

import '../auth_service.dart';

/// Google sign-in on desktop, done by hand.
///
/// `google_sign_in` has **no Windows implementation** — the primary dev
/// platform — so this runs the OAuth "installed app" flow itself: a throwaway
/// HTTP server on a loopback port, the system browser, and PKCE.
///
/// **The OAuth client must live in the same Google Cloud project as Firebase.**
/// This cost an afternoon once, because the symptom names the wrong thing:
/// Firebase reports `INVALID_IDP_RESPONSE` — "the supplied auth credential is
/// malformed or has expired" — for a token that is neither. Firebase only
/// accepts a Google ID token whose `aud` is a client of *its* project, so a
/// client borrowed from another project produces a flawless sign-in that is
/// then refused at the last step. If that message ever comes back, compare the
/// number prefixing `GOOGLE_OAUTH_CLIENT_ID` against the project number in
/// `firebase_options.dart` before suspecting anything else.
///
/// No redirect URI needs registering: an installed-app client may use **any**
/// `127.0.0.1` port, which is what lets this bind an OS-assigned one and never
/// collide with whatever else is running.
///
/// The client *secret* here is not confidential — a desktop client ships it in
/// its binary and Google knows that. **PKCE** is what actually secures the
/// exchange: the code is worthless without the verifier, which never leaves
/// this process. Both values still come from a gitignored `.env`, the same rule
/// the DeepSeek key follows.
class LoopbackGoogleFlow extends GoogleAuthFlow {
  final String clientId;
  final String? clientSecret;

  /// How long to wait on the browser before treating the attempt as abandoned.
  final Duration timeout;

  const LoopbackGoogleFlow({
    required this.clientId,
    this.clientSecret,
    this.timeout = const Duration(minutes: 3),
  });

  @override
  bool get isAvailable => clientId.isNotEmpty;

  @override
  Future<fb.AuthCredential?> authorize() async {
    if (!isAvailable) {
      throw const AuthFailure(
        'Google sign-in isn\'t configured — GOOGLE_OAUTH_CLIENT_ID is missing '
        'from .env.',
      );
    }

    // Port 0 = let the OS pick a free one. Bound before the browser opens so
    // the redirect can never arrive at a port nothing is listening on.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final redirectUri = 'http://127.0.0.1:${server.port}';
      final verifier = _randomToken();
      final state = _randomToken();

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'code_challenge': _challengeFor(verifier),
        'code_challenge_method': 'S256',
        // Round-trips untouched; anything else at this port is not our redirect.
        'state': state,
      });

      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw const AuthFailure('Couldn\'t open a browser for Google sign-in.');
      }

      final code = await _awaitCode(server, state);
      // Cancelled, denied, or abandoned — all of which are the user's choice,
      // not an error to show them.
      if (code == null) return null;

      final tokens = await _exchange(code, verifier, redirectUri);
      return fb.GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
    } finally {
      // Force-close: a browser keep-alive would otherwise hold the port open
      // well past the flow, and the next attempt binds a new one anyway.
      await server.close(force: true);
    }
  }

  /// Waits for Google's redirect. Returns the auth code, or null when the user
  /// denied consent or walked away.
  ///
  /// Loops rather than taking the first request: browsers fetch `/favicon.ico`
  /// against the same origin, and that must not be mistaken for the callback.
  Future<String?> _awaitCode(HttpServer server, String state) async {
    final completer = Completer<String?>();
    final sub = server.listen((request) async {
      final params = request.uri.queryParameters;
      final code = params['code'];
      final error = params['error'];
      if (code == null && error == null) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final ok = code != null && params['state'] == state;
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(_resultPage(ok));
      await request.response.close();

      if (!completer.isCompleted) completer.complete(ok ? code : null);
    }, onError: (_) {
      if (!completer.isCompleted) completer.complete(null);
    });

    try {
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } finally {
      await sub.cancel();
    }
  }

  Future<_Tokens> _exchange(
    String code,
    String verifier,
    String redirectUri,
  ) async {
    try {
      final res = await Dio().post<Map<String, dynamic>>(
        'https://oauth2.googleapis.com/token',
        data: {
          'code': code,
          'client_id': clientId,
          if (clientSecret != null && clientSecret!.isNotEmpty)
            'client_secret': clientSecret,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
          'code_verifier': verifier,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final body = res.data;
      final idToken = body?['id_token'];
      if (idToken is! String || idToken.isEmpty) {
        throw const AuthFailure('Google returned no ID token.');
      }
      final accessToken = body?['access_token'];
      return _Tokens(
        idToken: idToken,
        accessToken: accessToken is String ? accessToken : null,
      );
    } on DioException catch (e) {
      // Google puts the useful part in the body, not the status line.
      final detail = e.response?.data;
      final description = detail is Map ? detail['error_description'] : null;
      throw AuthFailure(
        description is String
            ? 'Google rejected the sign-in: $description'
            : 'Couldn\'t reach Google to complete sign-in.',
      );
    }
  }

  /// 32 secure random bytes, base64url without padding — a valid PKCE verifier
  /// (43 chars, all unreserved) and a good `state` nonce.
  static String _randomToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _challengeFor(String verifier) =>
      base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes)
          .replaceAll('=', '');

  /// What the browser tab shows once it has served its purpose. Inline styles
  /// only — this page has no origin to load anything from.
  static String _resultPage(bool ok) =>
      '<!doctype html><meta charset="utf-8">'
      '<title>Stocks Eye</title>'
      '<body style="margin:0;display:grid;place-items:center;height:100vh;'
      'background:#0E1420;color:#E7ECF5;'
      'font:15px system-ui,-apple-system,Segoe UI,sans-serif">'
      '<div style="text-align:center">'
      '<div style="font-size:22px;color:${ok ? "#E3A93C" : "#F26D6D"}">'
      '${ok ? "Signed in" : "Sign-in cancelled"}</div>'
      '<div style="margin-top:8px;color:#9AA6BC">'
      'You can close this tab and return to Stocks Eye.</div>'
      '</div></body>';
}

class _Tokens {
  final String idToken;
  final String? accessToken;
  const _Tokens({required this.idToken, this.accessToken});
}
