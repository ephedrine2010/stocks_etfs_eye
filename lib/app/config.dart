/// Build-time configuration.
///
/// The proxy URL is injected at build/run time so nothing is hard-coded:
///   flutter run -d windows --dart-define=PROXY_URL=http://localhost:3000
///
/// Empty (the default) ⇒ no proxy: AI stays on mock, and the Web build falls
/// back to mock for Yahoo/RSS. See [DataPolicy].
abstract class AppConfig {
  static const String proxyUrl =
      String.fromEnvironment('PROXY_URL', defaultValue: '');
}
