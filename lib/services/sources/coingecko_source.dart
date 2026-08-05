import 'package:dio/dio.dart';

import '../../data/models/models.dart';
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

  /// Timestamped USD price series for one coin over [range] — the chart feed.
  /// CoinGecko picks the granularity from `days` on the free tier (5-minutely
  /// for 1 day, hourly to 90 days, daily beyond), so no interval is requested.
  /// Returns `[]` when the payload carries no prices; never a filled-in series.
  static Future<List<PricePoint>> fetchSeries(String id, HistoryRange range) {
    return netCache.wrap('coingecko:hist:$id:${range.name}', range.ttl, () async {
      final res = await dio.get(
        '$_base/coins/${Uri.encodeComponent(id)}/market_chart',
        queryParameters: {'vs_currency': 'usd', 'days': '${range.coinDays}'},
        options: _json,
      );
      final prices = res.data?['prices'];
      if (prices is! List) return const <PricePoint>[];
      final points = <PricePoint>[];
      for (final row in prices) {
        if (row is! List || row.length < 2) continue;
        final ms = (row[0] as num?)?.toInt();
        final px = (row[1] as num?)?.toDouble();
        if (ms == null || px == null || !px.isFinite) continue;
        points.add(
          PricePoint(
            DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal(),
            px,
          ),
        );
      }
      return points;
    });
  }

  /// Coin lookup for the crypto market's "My stocks" search.
  ///
  /// Returns `[]` for no match AND for a failed lookup — both mean "nothing to
  /// add". Nothing is invented here: an id that doesn't exist upstream could
  /// never be priced or charted afterwards.
  static Future<List<SavedStock>> search(MarketConfig market, String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      return await netCache.wrap(
        'coingecko:search:${q.toLowerCase()}',
        const Duration(minutes: 5),
        () async {
          final res = await dio.get(
            '$_base/search',
            queryParameters: {'query': q},
            options: _json,
          );
          final coins = res.data?['coins'];
          if (coins is! List) return const <SavedStock>[];

          final out = <SavedStock>[];
          for (final row in coins) {
            if (row is! Map) continue;
            final id = row['id'];
            final symbol = row['symbol'];
            if (id is! String || id.isEmpty || symbol is! String) continue;
            final name = row['name'];
            out.add(
              SavedStock(
                marketId: market.id,
                symbol: symbol.toUpperCase(),
                name: name is String && name.isNotEmpty ? name : symbol,
                query: id,
                provider: 'coingecko',
              ),
            );
          }
          return out;
        },
      );
    } catch (_) {
      return const [];
    }
  }

  /// Live rows for user-added coins, in the leaders' shape so they render in
  /// the same table as equities. `dividend` is always null — a coin pays none,
  /// which the table already shows as "—" rather than a fake 0%.
  static Future<List<Leader>> fetchLeaderRows(List<SavedStock> stocks) async {
    if (stocks.isEmpty) return const [];
    final byId = {for (final s in stocks) s.query: s};
    final data = await _markets(byId.keys.toList());
    final out = <Leader>[];
    for (final d in data) {
      final ref = byId[d['id']];
      final price = (d['current_price'] as num?)?.toDouble();
      if (ref == null || price == null || !price.isFinite) continue;
      out.add(
        Leader(
          symbol: ref.symbol,
          name: ref.name,
          price: price,
          changePct: (d['price_change_percentage_24h'] as num?)?.toDouble() ?? 0,
        ),
      );
    }
    return out;
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
