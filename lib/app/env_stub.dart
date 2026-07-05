// Web fallback: no filesystem access, so there is no local .env to read.
// (Web uses the proxy for AI; it never sees the key.)
Future<Map<String, String>> loadDotEnv() async => const {};
