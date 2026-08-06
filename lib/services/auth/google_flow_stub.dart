import '../auth_service.dart';

/// Web. There is no `dart:io` here, so the loopback flow can't exist — and it
/// wouldn't be wanted anyway: `google_sign_in` has a real web implementation.
/// That is stage 3b and lands in this file; until then the UI correctly shows
/// no sign-in affordance on Web rather than a button that can't work.
GoogleAuthFlow googleAuthFlowFor({String? clientId, String? clientSecret}) =>
    const UnavailableGoogleAuthFlow();
