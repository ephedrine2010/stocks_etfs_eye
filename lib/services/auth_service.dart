import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../data/models/models.dart';

/// Acquires a Google credential on ONE platform.
///
/// This is the seam the platform split lives behind. `google_sign_in` does the
/// work on Android/iOS/macOS/Web; Windows has no implementation in that package
/// and needs a hand-rolled loopback OAuth + PKCE flow instead. [AuthService]
/// never learns which one it got — the same shape the data sources follow.
abstract class GoogleAuthFlow {
  const GoogleAuthFlow();

  /// Whether this platform can actually run the flow. False lets the UI say so
  /// plainly instead of offering a button that could only ever fail.
  bool get isAvailable;

  /// Runs the flow. Returns null when the user **cancelled** — a cancel is not
  /// a failure and must not surface as an error.
  Future<fb.AuthCredential?> authorize();

  /// Drop any account the flow itself cached, so the next sign-in asks again
  /// rather than silently reusing the last account. A no-op for flows that
  /// hold nothing.
  Future<void> signOut() async {}
}

/// The default on a platform whose flow isn't wired yet.
class UnavailableGoogleAuthFlow extends GoogleAuthFlow {
  const UnavailableGoogleAuthFlow();

  @override
  bool get isAvailable => false;

  @override
  Future<fb.AuthCredential?> authorize() async => null;
}

/// A sign-in attempt that failed for a reason worth showing the user.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

/// Sign-in, wrapped so nothing above it imports `firebase_auth`.
///
/// **Fail-soft, like the rest of the Firebase surface.** `main.dart` brings
/// Firebase up inside a try/catch because the dashboard is public market data
/// and must run without it, so every call here tolerates a Firebase that never
/// started and reports "unavailable" rather than throwing.
///
/// Nothing in the app is gated on this except "My stocks".
class AuthService {
  final GoogleAuthFlow flow;

  const AuthService({this.flow = const UnavailableGoogleAuthFlow()});

  /// Null when `Firebase.initializeApp()` didn't succeed at boot.
  fb.FirebaseAuth? get _auth {
    try {
      return fb.FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Signing in is possible here at all: Firebase came up **and** this platform
  /// has a flow.
  bool get isAvailable => _auth != null && flow.isAvailable;

  AuthUser? get current => _userFrom(_auth?.currentUser);

  /// Emits on every sign-in and sign-out. Falls back to a single "signed out"
  /// when Firebase never started, so a listener still gets its initial value
  /// and the UI settles instead of hanging on "unknown".
  Stream<AuthUser?> get changes {
    final auth = _auth;
    if (auth == null) return Stream.value(null);
    return auth.authStateChanges().map(_userFrom);
  }

  /// Returns null when the user cancelled the flow.
  Future<AuthUser?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw const AuthFailure("Sign-in is unavailable — Firebase didn't start.");
    }
    if (!flow.isAvailable) {
      throw const AuthFailure("Sign-in isn't supported on this platform yet.");
    }

    final credential = await flow.authorize();
    if (credential == null) return null;

    try {
      final result = await auth.signInWithCredential(credential);
      return _userFrom(result.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure(e.message ?? 'Google sign-in was rejected.');
    }
  }

  Future<void> signOut() async {
    await flow.signOut();
    await _auth?.signOut();
  }

  static AuthUser? _userFrom(fb.User? user) => user == null
      ? null
      : AuthUser(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoUrl: user.photoURL,
        );
}
