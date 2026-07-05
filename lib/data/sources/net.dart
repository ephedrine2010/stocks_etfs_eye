import 'package:dio/dio.dart';

/// Shared Dio instance for all live sources. Modest timeouts so a slow source
/// fails fast and the repository falls back to mock rather than hanging the UI.
final Dio dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 8),
    headers: const {'User-Agent': 'Mozilla/5.0'},
  ),
);

/// Tiny in-memory TTL cache — the Dart equivalent of the old `core/cache.js`
/// `wrap(key, ttl, fn)`. De-duplicates concurrent calls for the same key and
/// caches only successful results (a throw is never cached, mirroring the old
/// behaviour so one failure doesn't lock a stale value for the whole TTL).
class TtlCache {
  final _entries = <String, _Entry>{};
  final _inflight = <String, Future<Object?>>{};

  Future<T> wrap<T>(String key, Duration ttl, Future<T> Function() fetch) {
    final now = DateTime.now();
    final hit = _entries[key];
    if (hit != null && hit.expiry.isAfter(now)) {
      return Future.value(hit.value as T);
    }
    final pending = _inflight[key];
    if (pending != null) return pending.then((v) => v as T);

    final future = fetch().then((value) {
      _entries[key] = _Entry(value, now.add(ttl));
      return value;
    }).whenComplete(() {
      // NOTE: block body (not `=> _inflight.remove(key)`). An arrow would RETURN
      // the removed future — which is this very future — and whenComplete would
      // await it, deadlocking on itself.
      _inflight.remove(key);
    });

    _inflight[key] = future;
    return future;
  }
}

class _Entry {
  final Object? value;
  final DateTime expiry;
  _Entry(this.value, this.expiry);
}

/// Process-wide cache shared by the sources.
final TtlCache netCache = TtlCache();

/// Wrap a target URL through the proxy's generic `/api/fetch` forwarder when a
/// [proxyBase] is given (used on Web, where Yahoo/RSS are CORS-blocked); returns
/// the URL unchanged for direct calls (native).
String viaProxyUrl(String targetUrl, String? proxyBase) =>
    (proxyBase == null || proxyBase.isEmpty)
        ? targetUrl
        : '$proxyBase/api/fetch?url=${Uri.encodeComponent(targetUrl)}';

/// Evenly downsample a numeric series to [n] points (for sparklines).
List<double> downsample(List<double> arr, [int n = 14]) {
  final clean = arr.where((x) => x.isFinite).toList();
  if (clean.length <= n) return clean;
  final step = clean.length / n;
  return List.generate(n, (i) => clean[(i * step).floor()]);
}
