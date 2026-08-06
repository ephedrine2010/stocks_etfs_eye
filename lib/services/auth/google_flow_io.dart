import 'dart:io';

import '../auth_service.dart';
import 'loopback_google_flow.dart';

/// Desktop and mobile.
///
/// **Windows** is the one platform `google_sign_in` doesn't cover, so it gets
/// the hand-rolled loopback flow. Android/iOS/macOS are stage 3b — the package
/// does the work there and slots in below. Linux is absent on purpose: nothing
/// Firebase supports it, so a flow would have nothing to sign in to.
GoogleAuthFlow googleAuthFlowFor({String? clientId, String? clientSecret}) {
  if (Platform.isWindows) {
    // No client id means the .env wasn't filled in. Reporting "unavailable" is
    // better than a button that opens a browser onto a Google error page.
    if (clientId == null || clientId.isEmpty) {
      return const UnavailableGoogleAuthFlow();
    }
    return LoopbackGoogleFlow(clientId: clientId, clientSecret: clientSecret);
  }
  return const UnavailableGoogleAuthFlow();
}
