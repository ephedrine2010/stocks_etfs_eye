import 'package:flutter/foundation.dart' show kIsWeb;

/// How a given source should be reached on the current platform.
enum SourceMode { direct, proxy, mock }

/// The logical data sources the app pulls from.
enum DataSource { coingecko, yahoo, rss, deepseek, finnhub }

/// Decides, per platform + per source, whether to call directly, go through the
/// proxy, or fall back to mock — the single knob described in the build plan.
///
/// Mobile/desktop reach every source directly (no CORS). On Web, only CoinGecko
/// is CORS-friendly; Yahoo/RSS/DeepSeek must go through the proxy, and if none is
/// configured they degrade to mock so the app still runs.
class DataPolicy {
  /// Proxy base URL (e.g. `https://…`). Empty ⇒ no proxy configured.
  final String proxyBaseUrl;

  /// Whether a DeepSeek key was loaded from a local `.env` at runtime. When true
  /// (and not on Web), AI is called DIRECTLY — no proxy needed for desktop AI.
  /// The key itself lives in the repository, never in this policy.
  final bool directAiAvailable;

  /// Force every source to mock (no network). Used by widget tests so they stay
  /// deterministic and offline.
  final bool offline;

  const DataPolicy({
    this.proxyBaseUrl = '',
    this.directAiAvailable = false,
    this.offline = false,
  });

  bool get hasProxy => proxyBaseUrl.isNotEmpty;

  SourceMode modeFor(DataSource source) {
    if (offline) return SourceMode.mock;

    // CoinGecko and Finnhub work everywhere (CORS-enabled REST; Finnhub also
    // needs a key, but that's the repository's concern, not this policy's).
    if (source == DataSource.coingecko) return SourceMode.direct;
    if (source == DataSource.finnhub) return SourceMode.direct;

    if (!kIsWeb) {
      // Native: Yahoo/RSS direct. DeepSeek runs direct when a local key is
      // present, else via the proxy (never embed the key), else mock.
      if (source == DataSource.deepseek) {
        if (directAiAvailable) return SourceMode.direct;
        return hasProxy ? SourceMode.proxy : SourceMode.mock;
      }
      return SourceMode.direct;
    }

    // Web: everything non-CoinGecko needs the proxy, else mock (no filesystem,
    // so the direct key path never applies here).
    return hasProxy ? SourceMode.proxy : SourceMode.mock;
  }

  bool isLive(DataSource source) => modeFor(source) != SourceMode.mock;
}
