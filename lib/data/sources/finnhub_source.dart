import 'package:dio/dio.dart';

import '../models/models.dart';
import 'net.dart';

/// Finnhub adapter — LIVE real-time US stock/ETF quotes on the free tier (needs
/// an API key supplied via a local `.env`; see [loadDotEnv]). Used for markets
/// whose movers are US-listed (USA, Gold), where it gives true intraday moves
/// that Yahoo's close-to-close path can't. Each ticker fails soft (skipped, not
/// blanked) so the repository falls through to Yahoo and then mock.
///
/// Modularity: adding this source touched ONE file here + a few lines in
/// `dashboard_repository.dart` — the UI and models are untouched.
class FinnhubSource {
  final String apiKey;
  const FinnhubSource(this.apiKey);

  static const _base = 'https://finnhub.io/api/v1/quote';
  static final _opts = Options(responseType: ResponseType.json);

  /// One symbol's live quote → (price, changePct). Prefers Finnhub's own `dp`
  /// (percent change vs the prior close); falls back to computing it from `c`
  /// (current) and `pc` (previous close). Throws on an empty/unknown reply — the
  /// free tier returns `c: 0` for symbols it doesn't cover (e.g. non-US names).
  Future<({double price, double changePct})> _quoteOf(String symbol) async {
    final res = await dio.get(
      '$_base?symbol=${Uri.encodeComponent(symbol)}&token=$apiKey',
      options: _opts,
    );
    final data = res.data as Map?;
    final price = (data?['c'] as num?)?.toDouble();
    if (price == null || price == 0 || !price.isFinite) {
      throw Exception('Finnhub: no price for $symbol');
    }
    final dp = (data?['dp'] as num?)?.toDouble();
    final pc = (data?['pc'] as num?)?.toDouble();
    final changePct = (dp != null && dp.isFinite)
        ? dp
        : (pc != null && pc != 0 ? ((price - pc) / pc) * 100 : 0.0);
    return (price: price, changePct: changePct);
  }

  /// Live movers from a market's curated list, each cached 60s (matching the
  /// Yahoo path). A failed or uncovered ticker is skipped, never blanked.
  Future<List<Mover>> fetchMovers(MarketConfig market) async {
    if (market.movers.isEmpty) return const [];
    final rows = await Future.wait(market.movers.map((m) async {
      try {
        return await netCache.wrap(
          'finnhub:t:${m.symbol}',
          const Duration(seconds: 60),
          () async {
            final q = await _quoteOf(m.symbol);
            return Mover(
              symbol: m.symbol,
              name: m.name,
              price: q.price,
              changePct: q.changePct,
            );
          },
        );
      } catch (_) {
        return null;
      }
    }));
    return rows.whereType<Mover>().toList();
  }
}
