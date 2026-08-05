import '../app/data_policy.dart';
import '../data/models/models.dart';
import 'sources/coingecko_source.dart';
import 'sources/yahoo_source.dart';

/// Finds instruments that aren't in a market's curated config, and prices the
/// ones the user kept.
///
/// Same shape as `PriceHistoryService`: it routes to an adapter, honours
/// [DataPolicy] (Yahoo goes through the proxy on Web), and returns the
/// normalized model. It is **not** part of `DashboardRepository.load()` — a
/// search runs only when the user types, and saved rows are priced only while
/// the dialog holding them is open.
///
/// **It never falls back to mock.** An invented search result could not be
/// priced or charted after it was added, so an empty list is the honest answer
/// to both "no match" and "the lookup failed" — the same rule the price curves
/// follow.
class MyStocksService {
  final DataPolicy policy;

  const MyStocksService({this.policy = const DataPolicy()});

  String? _proxyFor(DataSource s) =>
      policy.modeFor(s) == SourceMode.proxy ? policy.proxyBaseUrl : null;

  /// Which source backs a market: coins for crypto, Yahoo for everything else.
  DataSource _sourceFor(MarketConfig market) =>
      market.coins.isNotEmpty ? DataSource.coingecko : DataSource.yahoo;

  /// Whether this platform can search this market at all — lets the UI hide the
  /// affordance rather than offer a box that can only ever come back empty.
  /// (Web with no proxy can't reach Yahoo; crypto still works there.)
  bool canSearch(MarketConfig market) => policy.isLive(_sourceFor(market));

  /// Instruments matching [query] within [market]'s own exchange.
  Future<List<SavedStock>> search(MarketConfig market, String query) {
    if (!canSearch(market)) return Future.value(const []);
    return market.coins.isNotEmpty
        ? CoinGeckoSource.search(market, query)
        : YahooSource.search(
            market,
            query,
            proxyBase: _proxyFor(DataSource.yahoo),
          );
  }

  /// Live rows for a market's saved stocks, in the leaders' shape so they
  /// render in the same table. A row that can't be priced is dropped, never
  /// shown blank or zeroed.
  Future<List<Leader>> rows(MarketConfig market, List<SavedStock> saved) async {
    if (saved.isEmpty || !canSearch(market)) return const [];
    try {
      final coins = saved.where((s) => s.provider == 'coingecko').toList();
      final equities = saved.where((s) => s.provider == 'yahoo').toList();

      // Coins go in ONE batched call (CoinGecko's free tier is rate-limited);
      // equities are per-ticker but share the 15m leader cache with the
      // curated rows, so an overlap costs nothing.
      final results = await Future.wait([
        if (coins.isNotEmpty) CoinGeckoSource.fetchLeaderRows(coins),
        ...equities.map((s) async {
          final row = await YahooSource.fetchLeaderRow(
            s,
            proxyBase: _proxyFor(DataSource.yahoo),
          );
          return row == null ? const <Leader>[] : <Leader>[row];
        }),
      ]);

      // Re-order to the user's own list rather than whatever order the fetches
      // happened to resolve in.
      final bySymbol = {
        for (final list in results)
          for (final row in list) row.symbol: row,
      };
      return saved.map((s) => bySymbol[s.symbol]).whereType<Leader>().toList();
    } catch (_) {
      return const [];
    }
  }
}
