// Loads a local `.env` at runtime. Uses the dart:io implementation on
// desktop/mobile and a no-op stub on Web (which has no filesystem and uses the
// proxy for AI instead).
export 'env_stub.dart' if (dart.library.io) 'env_io.dart';
