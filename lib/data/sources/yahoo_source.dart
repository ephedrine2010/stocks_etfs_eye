import 'package:dio/dio.dart';

import '../models/models.dart';
import 'net.dart';

/// Yahoo Finance adapter — LIVE, no key (unofficial public endpoint). Covers the
/// equity/gold headline indices, per-market movers, and leading stocks +
/// dividends. Returns null / throws on failure so the repository falls back to
/// mock — never a blank tile. Ported from the old `services/prices/yahoo.js`.
class YahooSource {
  static const _base = 'https://query1.finance.yahoo.com/v8/finance/chart';

  static final _opts = Options(responseType: ResponseType.json);

  /// Fetch + parse one symbol's daily chart.
  ///
  /// Daily change uses the prior-day close (NOT `chartPreviousClose`, which is
  /// range-relative — see the old CLAUDE.md gotcha). Pass [events] = 'div' to
  /// also pull dividend events in the same call.
  static Future<_Chart> _fetchChart(
    String symbol,
    String range, {
    String? events,
    String? proxyBase,
  }) async {
    final target = '$_base/${Uri.encodeComponent(symbol)}'
        '?range=$range&interval=1d${events != null ? '&events=$events' : ''}';
    final res = await dio.get(
      viaProxyUrl(target, proxyBase),
      options: _opts,
    );
    final result = res.data?['chart']?['result']?[0];
    final meta = result?['meta'];
    final price = (meta?['regularMarketPrice'] as num?)?.toDouble();
    if (price == null || !price.isFinite) throw Exception('Yahoo: no price');

    final rawCloses =
        (result?['indicators']?['quote']?[0]?['close'] as List?) ?? const [];
    final closes = rawCloses
        .where((x) => x != null)
        .map((x) => (x as num).toDouble())
        .toList();

    final prevDay = closes.length >= 2 ? closes[closes.length - 2] : null;
    final metaPrev = (meta?['previousClose'] as num?)?.toDouble();
    final metaChartPrev = (meta?['chartPreviousClose'] as num?)?.toDouble();
    final prev = (metaPrev != null && metaPrev.isFinite)
        ? metaPrev
        : (prevDay ?? metaChartPrev);
    if (prev == null || !prev.isFinite) {
      throw Exception('Yahoo: no previous close');
    }

    final divMap = result?['events']?['dividends'] as Map?;
    final dividends = divMap == null
        ? <Map>[]
        : (divMap.values.cast<Map>().toList()
          ..sort((a, b) => (a['date'] as num).compareTo(b['date'] as num)));

    return _Chart(
      price: price,
      changePct: prev != 0 ? ((price - prev) / prev) * 100 : 0,
      closes: closes,
      dividends: dividends,
    );
  }

  /// Headline index/gold quote (cached 60s). Crypto is handled by CoinGecko.
  static Future<Quote?> fetchQuote(MarketConfig market, {String? proxyBase}) {
    if (market.coins.isNotEmpty) return Future.value(null);
    final symbol = market.index.symbol;
    return netCache.wrap('yahoo:$symbol', const Duration(seconds: 60), () async {
      final c = await _fetchChart(symbol, '1mo', proxyBase: proxyBase);
      return Quote(
        price: c.price,
        changePct: c.changePct,
        spark: downsample(c.closes),
        source: 'Yahoo',
        currency: market.currency,
        asOf: DateTime.now(),
      );
    });
  }

  /// Live movers from a market's curated list. Each ticker is priced
  /// close-to-close (same scale for price and change — avoids the EGX `.CA`
  /// live-price bug). A failed ticker is skipped, not blanked.
  static Future<List<Mover>> fetchMovers(MarketConfig market,
      {String? proxyBase}) async {
    if (market.movers.isEmpty) return const [];
    final rows = await Future.wait(market.movers.map((m) async {
      try {
        return await netCache.wrap(
          'yahoo:t:${m.yahooTicker}',
          const Duration(seconds: 60),
          () async {
            final c = await _fetchChart(m.yahooTicker, '5d', proxyBase: proxyBase);
            if (c.closes.length < 2) throw Exception('not enough closes');
            final price = c.closes.last;
            final prev = c.closes[c.closes.length - 2];
            return Mover(
              symbol: m.symbol,
              name: m.name,
              price: price,
              changePct: prev != 0 ? ((price - prev) / prev) * 100 : 0,
            );
          },
        );
      } catch (_) {
        return null;
      }
    }));
    return rows.whereType<Mover>().toList();
  }

  /// Live leading stocks + dividends, ranked by config order (weight). Priced
  /// close-to-close with a dividend summary from ONE fetch (range=2y&events=div),
  /// cached longer than movers. Failure skips the row.
  static Future<List<Leader>> fetchLeaders(MarketConfig market,
      {String? proxyBase}) async {
    if (market.leaders.isEmpty) return const [];
    final rows = await Future.wait(market.leaders.map((m) async {
      try {
        return await netCache.wrap(
          'yahoo:lead:${m.yahooTicker}',
          const Duration(minutes: 15),
          () async {
            final c = await _fetchChart(m.yahooTicker, '2y',
                events: 'div', proxyBase: proxyBase);
            if (c.closes.length < 2) throw Exception('not enough closes');
            final price = c.closes.last;
            final prev = c.closes[c.closes.length - 2];
            return Leader(
              symbol: m.symbol,
              name: m.name,
              price: price,
              changePct: prev != 0 ? ((price - prev) / prev) * 100 : 0,
              dividend: _summarizeDividends(c.dividends, price),
            );
          },
        );
      } catch (_) {
        return null;
      }
    }));
    return rows.whereType<Leader>().toList();
  }

  /// Summarize raw Yahoo dividend events → {yield, annual, exDate, frequency},
  /// or null for a genuine non-payer (so the UI hides the field, never "0%").
  /// Yield = trailing-12-month payout ÷ price (currency-neutral).
  static Dividend? _summarizeDividends(List<Map> events, double price) {
    if (events.isEmpty || price <= 0) return null;
    final cutoff = DateTime.now().millisecondsSinceEpoch / 1000 - 365 * 24 * 3600;
    final ttm =
        events.where((e) => (e['date'] as num?) != null && e['date'] >= cutoff);
    if (ttm.isEmpty) return null;
    final annual =
        ttm.fold<double>(0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
    if (annual <= 0) return null;
    final n = ttm.length;
    final frequency = n >= 11
        ? 'Monthly'
        : n >= 4
        ? 'Quarterly'
        : n >= 2
        ? 'Semi-annual'
        : 'Annual';
    final last = events.last;
    final exDate = (last['date'] as num?) != null
        ? DateTime.fromMillisecondsSinceEpoch((last['date'] as num).toInt() * 1000,
                isUtc: true)
            .toIso8601String()
            .substring(0, 10)
        : null;
    return Dividend(
      yield: (annual / price) * 100,
      annual: annual,
      exDate: exDate,
      frequency: frequency,
    );
  }
}

class _Chart {
  final double price;
  final double changePct;
  final List<double> closes;
  final List<Map> dividends;
  _Chart({
    required this.price,
    required this.changePct,
    required this.closes,
    required this.dividends,
  });
}
