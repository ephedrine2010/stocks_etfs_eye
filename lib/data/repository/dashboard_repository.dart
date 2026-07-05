import '../../app/data_policy.dart';
import '../config/markets.dart';
import '../models/models.dart';
import '../sources/ai_proxy_source.dart';
import '../sources/ai_source.dart';
import '../sources/coingecko_source.dart';
import '../sources/deepseek_source.dart';
import '../sources/finnhub_source.dart';
import '../sources/mock_source.dart';
import '../sources/rss_source.dart';
import '../sources/yahoo_source.dart';
import 'market_hours.dart';

/// Assembles the full [Dashboard] from the individual sources — the Dart
/// equivalent of the old `services/dashboard.js` aggregator, and the ONLY place
/// sources are stitched together.
///
/// Each piece tries its live source (subject to [DataPolicy]) and falls back to
/// mock on any failure, so a tile is never blank. AI (take/brief) is wired in M4.
class DashboardRepository {
  final DataPolicy policy;

  /// DeepSeek key from a local `.env` (desktop) — enables direct AI. Never set
  /// on Web.
  final String? deepSeekKey;

  /// Finnhub key from a local `.env` — enables live real-time US quotes. Absent
  /// ⇒ the movers path just falls through to Yahoo.
  final String? finnhubKey;

  const DashboardRepository({
    this.policy = const DataPolicy(),
    this.deepSeekKey,
    this.finnhubKey,
  });

  /// The active AI backend for this platform/config: direct DeepSeek (desktop
  /// with a local key), the proxy, or none (→ mock).
  AiSource? get _ai => switch (policy.modeFor(DataSource.deepseek)) {
    SourceMode.direct =>
      (deepSeekKey != null && deepSeekKey!.isNotEmpty)
          ? DeepSeekSource(deepSeekKey!)
          : null,
    SourceMode.proxy => AiProxySource(policy.proxyBaseUrl),
    SourceMode.mock => null,
  };

  /// Proxy base to route a source's HTTP through, or null for a direct call.
  String? _proxyFor(DataSource s) =>
      policy.modeFor(s) == SourceMode.proxy ? policy.proxyBaseUrl : null;

  /// Live Finnhub client when a key is present and the source is live, else null.
  FinnhubSource? get _finnhub =>
      (finnhubKey != null &&
              finnhubKey!.isNotEmpty &&
              policy.isLive(DataSource.finnhub))
          ? FinnhubSource(finnhubKey!)
          : null;

  /// Whether a market's movers can be served by Finnhub: a key is present and
  /// every ticker is US-listed (no market suffix like `.SR`/`.CA`/`.SS`, which
  /// the free tier doesn't cover). This selects USA and Gold.
  bool _finnhubMovers(MarketConfig m) =>
      _finnhub != null &&
      m.movers.isNotEmpty &&
      m.movers.every((r) =>
          !r.yahooTicker.contains('.') && !r.yahooTicker.contains('^'));

  Future<Dashboard> load() async {
    // Build market data first; the AI take/brief are grounded on it.
    var markets = await Future.wait(kMarkets.map(_buildMarket));
    markets = await _attachTakes(markets);
    return Dashboard(
      markets: markets,
      watchlist: _buildWatchlist(markets),
      brief: await _brief(markets),
      asOf: DateTime.now(),
    );
  }

  Future<Market> _buildMarket(MarketConfig config) async {
    final results = await Future.wait([
      _quote(config),
      _movers(config),
      _leaders(config),
      _news(config),
    ]);
    return Market(
      config: config,
      quote: results[0] as Quote,
      movers: results[1] as List<Mover>,
      leaders: results[2] as List<Leader>,
      news: results[3] as List<NewsItem>,
      take: MockSource.take(config.id), // upgraded to live below when proxied
    );
  }

  /// Per-market AI Take: live via the proxy when configured, else mock.
  /// (Takes are gated to mock on the proxy by default → returns null → mock.)
  Future<List<Market>> _attachTakes(List<Market> markets) async {
    final ai = _ai;
    if (ai == null) return markets;
    return Future.wait(markets.map((m) async {
      final take = await ai.fetchTake(m.config, _snapshot(m));
      return take == null ? m : m.copyWith(take: take);
    }));
  }

  /// Roll-up Morning Brief: live via the proxy when configured, else mock.
  Future<Brief> _brief(List<Market> markets) async {
    final ai = _ai;
    if (ai != null) {
      final live = await ai.fetchBrief(markets.map(_snapshot).toList());
      if (live != null) return live;
    }
    return MockSource.brief();
  }

  /// The ground-truth snapshot handed to the model (numbers only).
  Map<String, dynamic> _snapshot(Market m) => {
    'id': m.id,
    'name': m.name,
    'index': m.indexLabel,
    'price': m.quote.price,
    'changePct': m.quote.changePct,
    'open': MarketHours.isOpen(m.schedule),
  };

  Future<Quote> _quote(MarketConfig m) async {
    try {
      if (m.priceSource == 'coingecko' &&
          policy.isLive(DataSource.coingecko)) {
        final q = await CoinGeckoSource.fetchQuote(m);
        if (q != null) return q;
      } else if (policy.isLive(DataSource.yahoo)) {
        // 'yahoo' and 'sahmk' both resolve to Yahoo here (SAHMK not yet ported).
        final q = await YahooSource.fetchQuote(m, proxyBase: _proxyFor(DataSource.yahoo));
        if (q != null) return q;
      }
    } catch (_) {/* fall through */}
    return MockSource.quote(m);
  }

  Future<List<Mover>> _movers(MarketConfig m) async {
    try {
      if (m.coins.isNotEmpty && policy.isLive(DataSource.coingecko)) {
        final live = await CoinGeckoSource.fetchCoins(m);
        if (live.isNotEmpty) return live;
      } else if (m.movers.isNotEmpty) {
        // Prefer Finnhub (real-time) for US-listed movers; else Yahoo.
        if (_finnhubMovers(m)) {
          final live = await _finnhub!.fetchMovers(m);
          if (live.isNotEmpty) return live;
        }
        if (policy.isLive(DataSource.yahoo)) {
          final live = await YahooSource.fetchMovers(m, proxyBase: _proxyFor(DataSource.yahoo));
          if (live.isNotEmpty) return live;
        }
      }
    } catch (_) {/* fall through */}
    return MockSource.movers(m.id);
  }

  Future<List<Leader>> _leaders(MarketConfig m) async {
    if (m.leaders.isEmpty || !policy.isLive(DataSource.yahoo)) return const [];
    try {
      return await YahooSource.fetchLeaders(m, proxyBase: _proxyFor(DataSource.yahoo));
    } catch (_) {
      return const [];
    }
  }

  Future<List<NewsItem>> _news(MarketConfig m) async {
    if (m.newsSource == 'rss' &&
        m.newsFeeds.isNotEmpty &&
        policy.isLive(DataSource.rss)) {
      try {
        final items = await RssSource.fetchFeed(
          m.newsFeeds.first,
          _feedLabel(m.newsFeeds.first),
          proxyBase: _proxyFor(DataSource.rss),
        );
        if (items.isNotEmpty) return items;
      } catch (_) {/* fall through */}
    }
    return MockSource.news(m.id);
  }

  /// Refresh the mock watchlist's crypto & gold rows with live USD prices.
  List<WatchRow> _buildWatchlist(List<Market> markets) {
    final byId = {for (final m in markets) m.id: m};
    return MockSource.watchlist().map((row) {
      final live = byId[row.id]?.quote;
      if ((row.id == 'cr' || row.id == 'au') &&
          live != null &&
          live.source != 'mock') {
        final px = '\$${_grouped(live.price)}';
        return row.copyWith(native: px, usd: px, changePct: live.changePct);
      }
      return row;
    }).toList();
  }

  static String _grouped(double n) {
    final s = n.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$intPart.${parts[1]}';
  }

  static String _feedLabel(String url) {
    try {
      return Uri.parse(url).host.replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return 'RSS';
    }
  }
}
