// Picks the Google sign-in flow for the platform being compiled for.
//
// Same shape as `app/env.dart`: the `dart:io` implementation on desktop/mobile
// and a stub on Web, so a `flutter build web` never sees `HttpServer`.
export 'google_flow_stub.dart' if (dart.library.io) 'google_flow_io.dart';
