import 'package:dio/dio.dart';

import '../../data/models/models.dart';
import 'net.dart';

/// Yahoo Finance adapter — LIVE, no key (unofficial public endpoint). Covers the
/// equity/gold headline indices, per-market movers, and leading stocks +
/// dividends. Returns null / throws on failure so the repository falls back to
/// mock — never a blank tile. Ported from the old `services/prices/yahoo.js`.
class YahooSource {
  static const _base = 'https://query1.finance.yahoo.com/v8/finance/chart';
  static const _searchBase = 'https://query1.finance.yahoo.com/v1/finance/search';

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

  /// Timestamped close series for one ticker over [range] — the chart feed.
  ///
  /// Separate from [_fetchChart] on purpose: that one exists to derive a daily
  /// change and hard-codes `interval=1d`, while this one varies the interval and
  /// keeps the timestamps. Returns `[]` when Yahoo has no usable series — the
  /// caller shows "N.A."; nothing here ever invents a point.
  static Future<List<PricePoint>> fetchSeries(
    String symbol,
    HistoryRange range, {
    String? proxyBase,
  }) {
    return netCache.wrap('yahoo:hist:$symbol:${range.name}', range.ttl, () async {
      final target = '$_base/${Uri.encodeComponent(symbol)}'
          '?range=${range.yahooRange}&interval=${range.yahooInterval}';
      final res = await dio.get(viaProxyUrl(target, proxyBase), options: _opts);
      final result = res.data?['chart']?['result']?[0];
      final stamps = (result?['timestamp'] as List?) ?? const [];
      final closes =
          (result?['indicators']?['quote']?[0]?['close'] as List?) ?? const [];
      if (stamps.isEmpty || closes.length != stamps.length) {
        return const <PricePoint>[];
      }

      final points = <PricePoint>[];
      for (var i = 0; i < stamps.length; i++) {
        // Yahoo pads gaps (holidays, halts) with nulls — skip, never fill.
        final close = (closes[i] as num?)?.toDouble();
        final stamp = (stamps[i] as num?)?.toInt();
        if (close == null || !close.isFinite || stamp == null) continue;
        points.add(
          PricePoint(
            DateTime.fromMillisecondsSinceEpoch(stamp * 1000, isUtc: true)
                .toLocal(),
            close,
          ),
        );
      }
      return points;
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
    final rows = await Future.wait(market.leaders.map(
      (m) => _leaderFor(m.yahooTicker, m.symbol, m.name, proxyBase: proxyBase),
    ));
    return rows.whereType<Leader>().toList();
  }

  /// One leading-stock row for an arbitrary ticker — the feed behind a
  /// user-added stock, so an added row renders identically to a curated leader
  /// (price · change · dividend) instead of being a second-class shape.
  /// Null when Yahoo can't price it; the caller drops the row.
  static Future<Leader?> fetchLeaderRow(SavedStock stock, {String? proxyBase}) =>
      _leaderFor(stock.query, stock.symbol, stock.name, proxyBase: proxyBase);

  /// The shared body of both leader paths. Cached per ticker (15m), so a stock
  /// that is both curated and user-added costs one fetch, not two.
  static Future<Leader?> _leaderFor(
    String ticker,
    String symbol,
    String name, {
    String? proxyBase,
  }) async {
    try {
      return await netCache.wrap(
        'yahoo:lead:$ticker',
        const Duration(minutes: 15),
        () async {
          final c = await _fetchChart(ticker, '2y',
              events: 'div', proxyBase: proxyBase);
          if (c.closes.length < 2) throw Exception('not enough closes');
          final price = c.closes.last;
          final prev = c.closes[c.closes.length - 2];
          return Leader(
            symbol: symbol,
            name: name,
            price: price,
            changePct: prev != 0 ? ((price - prev) / prev) * 100 : 0,
            dividend: _summarizeDividends(c.dividends, price),
          );
        },
      );
    } catch (_) {
      return null;
    }
  }

  /// Ticker / company lookup, scoped to [market]'s own exchange(s).
  ///
  /// Yahoo's search is global, so results are filtered to the suffixes the
  /// market's config already uses. An added row inherits the dialog's currency
  /// and trading session, so a foreign listing sitting there would be labelled
  /// wrong — filtering is what keeps the list truthful, not tidiness.
  ///
  /// Returns `[]` for no match AND for a failed lookup: both mean "nothing to
  /// add". Nothing here is ever mocked — an invented ticker would be unaddable.
  static Future<List<SavedStock>> search(
    MarketConfig market,
    String query, {
    String? proxyBase,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final suffixes = _suffixesFor(market);
    final target = '$_searchBase?q=${Uri.encodeQueryComponent(q)}'
        '&quotesCount=20&newsCount=0&listsCount=0';
    try {
      return await netCache.wrap(
        'yahoo:search:${market.id}:${q.toLowerCase()}',
        const Duration(minutes: 5),
        () async {
          final res = await dio.get(viaProxyUrl(target, proxyBase), options: _opts);
          final quotes = res.data?['quotes'];
          if (quotes is! List) return const <SavedStock>[];

          final out = <SavedStock>[];
          for (final row in quotes) {
            if (row is! Map) continue;
            final ticker = row['symbol'];
            if (ticker is! String || ticker.isEmpty) continue;
            final type = (row['quoteType'] as String?)?.toUpperCase();
            if (type != 'EQUITY' && type != 'ETF') continue;
            if (!_matchesMarket(ticker, suffixes)) continue;
            final name = row['longname'] ?? row['shortname'];
            out.add(
              SavedStock(
                marketId: market.id,
                symbol: _displaySymbol(ticker, suffixes),
                name: name is String && name.isNotEmpty ? name : ticker,
                query: ticker,
                provider: 'yahoo',
              ),
            );
          }
          if (out.isNotEmpty) return out;

          // Nothing in the index — try the query as a ticker (see below).
          return _probeAsTicker(market, q, suffixes, proxyBase: proxyBase);
        },
      );
    } catch (_) {
      return const [];
    }
  }

  /// Last resort when a scoped search comes back empty: treat the query as a
  /// ticker on this market's exchange and keep it only if Yahoo really prices
  /// it.
  ///
  /// Yahoo's *search* index doesn't cover every exchange its *chart* endpoint
  /// serves — EGX (`.CA`) returns nothing for any query, yet `COMI.CA` prices
  /// fine, which is why Egypt's movers work at all. Without this, Egypt could
  /// never add a stock.
  ///
  /// This is a verification, not a guess: the ticker is offered only after a
  /// real quote comes back for it, so nothing unpriceable ever reaches the list.
  static Future<List<SavedStock>> _probeAsTicker(
    MarketConfig market,
    String query,
    Set<String> suffixes, {
    String? proxyBase,
  }) async {
    final base = query.trim().toUpperCase();
    // A multi-word query is a company name, not a ticker.
    if (base.isEmpty || base.contains(' ')) return const [];

    for (final suffix in suffixes) {
      final ticker = (suffix.isNotEmpty && base.endsWith(suffix))
          ? base
          : '$base$suffix';
      try {
        final target =
            '$_base/${Uri.encodeComponent(ticker)}?range=5d&interval=1d';
        final res = await dio.get(viaProxyUrl(target, proxyBase), options: _opts);
        final meta = res.data?['chart']?['result']?[0]?['meta'];
        final price = (meta?['regularMarketPrice'] as num?)?.toDouble();
        if (price == null || !price.isFinite) continue;
        final name = meta?['longName'] ?? meta?['shortName'];
        return [
          SavedStock(
            marketId: market.id,
            symbol: _displaySymbol(ticker, suffixes),
            name: name is String && name.isNotEmpty ? name : ticker,
            query: ticker,
            provider: 'yahoo',
          ),
        ];
      } catch (_) {
        // Not a ticker on this exchange — try the market's next suffix.
      }
    }
    return const [];
  }

  /// The Yahoo suffixes a market's config already uses — `{'.SR'}` for KSA,
  /// `{'.SS', '.SZ'}` for China, `{''}` for US-listed. Derived rather than a
  /// second table to maintain, so adding a market stays ONE entry in
  /// `markets.dart`.
  ///
  /// Reads `movers` + `leaders` only: `watch` refs omit the `yahoo:` field, so
  /// including them would contribute a bogus empty suffix and let US tickers
  /// into, say, the KSA list.
  static Set<String> _suffixesFor(MarketConfig market) {
    final out = <String>{};
    for (final r in [...market.movers, ...market.leaders]) {
      final t = r.yahooTicker.toUpperCase();
      final dot = t.lastIndexOf('.');
      out.add(dot > 0 ? t.substring(dot) : '');
    }
    return out.isEmpty ? const {''} : out;
  }

  static bool _matchesMarket(String ticker, Set<String> suffixes) {
    final t = ticker.toUpperCase();
    final dot = t.lastIndexOf('.');
    return suffixes.contains(dot > 0 ? t.substring(dot) : '');
  }

  /// Strip the exchange suffix for display (`1150.SR` → `1150`), matching how
  /// the curated refs show. Only a suffix this market actually uses is removed,
  /// so a US ticker that genuinely contains a dot is left alone.
  static String _displaySymbol(String ticker, Set<String> suffixes) {
    final upper = ticker.toUpperCase();
    for (final s in suffixes) {
      if (s.isNotEmpty && upper.endsWith(s)) {
        return ticker.substring(0, ticker.length - s.length);
      }
    }
    return ticker;
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
