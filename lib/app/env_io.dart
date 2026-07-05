import 'dart:io';

/// Reads a local `.env` file at runtime (desktop/mobile only) into a map, so the
/// DeepSeek key can live on disk rather than being compiled into the app.
///
/// Searches, in order: the current working directory (where `flutter run`
/// starts), then the directory next to the executable (for a built/distributed
/// app). Parses simple `KEY=VALUE` lines; `#` comments and quotes are handled.
Future<Map<String, String>> loadDotEnv() async {
  for (final path in _candidates()) {
    final file = File(path);
    if (await file.exists()) {
      return _parse(await file.readAsString());
    }
  }
  return const {};
}

List<String> _candidates() {
  final sep = Platform.pathSeparator;
  final paths = <String>['.env'];
  try {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    paths.add('$exeDir$sep.env');
  } catch (_) {/* ignore */}
  return paths;
}

Map<String, String> _parse(String content) {
  final out = <String, String>{};
  for (final raw in content.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq == -1) continue;
    final key = line.substring(0, eq).trim();
    var val = line.substring(eq + 1).trim();
    if (val.length >= 2 &&
        ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'")))) {
      val = val.substring(1, val.length - 1);
    }
    out[key] = val;
  }
  return out;
}
