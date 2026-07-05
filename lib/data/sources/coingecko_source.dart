import 'package:dio/dio.dart';

import '../models/models.dart';
import 'net.dart';

final _json = Options(responseType: ResponseType.json, headers: {
  'accept': 'application/json',
});

/// CoinGecko price adapter — LIVE, no API key. Powers the Crypto market.
/// https://www.coingecko.com/en/api . CORS-enabled, so it works on Web too.
class CoinGeckoSource {
  static const _base = 'https://api.coingecko.com/api/v3';

  /// Raw /coins/markets payload for a set of ids (cached 60s).
  static Future<List<dynamic>> _markets(List<String> ids) {
    final key = 'coingecko:${ids.join(',')}';
    return netCache.wrap(key, const Duration(seconds: 60), () async {
      final res = await dio.get(
        '$_base/coins/markets',
        queryParameters: {
          'vs_currency': 'usd',
          'ids': ids.join(','),
          'order': 'market_cap_desc',
          'price_change_percentage': '24h',
          'sparkline': 'true',
        },
        options: _json,
      );
      final data = res.data;
      if (data is! List) throw Exception('CoinGecko: bad payload');
      return data;
    });
  }

  /// Headline quote (e.g. BTC/USD) for the crypto market.
  static Future<Quote?> fetchQuote(MarketConfig market) async {
    if (market.coins.isEmpty) return null;
    final ids = market.coins.map((c) => c.id).toList();
    final data = await _markets(ids);
    final head = data.firstWhere(
      (d) => d['id'] == market.index.symbol,
      orElse: () => data.isNotEmpty ? data.first : null,
    );
    if (head == null) return null;
    final spark = ((head['sparkline_in_7d']?['price'] as List?) ?? const [])
        .map((e) => (e as num).toDouble())
        .toList();
    return Quote(
      price: (head['current_price'] as num).toDouble(),
      changePct: (head['price_change_percentage_24h'] as num?)?.toDouble() ?? 0,
      spark: downsample(spark),
      source: 'CoinGecko',
      currency: 'USD',
      asOf: DateTime.now(),
    );
  }

  /// All coins as movers rows.
  static Future<List<Mover>> fetchCoins(MarketConfig market) async {
    if (market.coins.isEmpty) return const [];
    final ids = market.coins.map((c) => c.id).toList();
    final data = await _markets(ids);
    final bySymbol = {for (final c in market.coins) c.id: c};
    return data.map((d) {
      final ref = bySymbol[d['id']];
      return Mover(
        symbol: ref?.symbol ?? (d['symbol'] as String).toUpperCase(),
        name: d['name'] as String,
        changePct: (d['price_change_percentage_24h'] as num?)?.toDouble() ?? 0,
        price: (d['current_price'] as num).toDouble(),
      );
    }).toList();
  }
}
