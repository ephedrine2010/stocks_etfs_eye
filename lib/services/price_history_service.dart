import '../app/data_policy.dart';
import '../data/models/models.dart';
import 'sources/coingecko_source.dart';
import 'sources/yahoo_source.dart';

/// Which adapter can serve a given instrument's history.
enum HistoryProvider { yahoo, coingecko }

/// A thing a curve can be drawn for, already resolved to the id its source
/// wants (a Yahoo ticker with its market suffix, or a CoinGecko coin id).
///
/// Build one with a factory — the UI passes the display symbol it has on screen
/// and the market it belongs to, and the resolution to a queryable id stays
/// here, out of the widgets.
class HistoryTarget {
  final HistoryProvider provider;

  /// The id handed to the source: `2222.SR`, `AAPL`, `bitcoin`.
  final String query;

  /// What the user sees: the display ticker and the company/coin name.
  final String symbol;
  final String name;

  final String currency;

  const HistoryTarget({
    required this.provider,
    required this.query,
    required this.symbol,
    required this.name,
    required this.currency,
  });

  /// The market's own headline index.
  factory HistoryTarget.index(MarketConfig market) => market.coins.isNotEmpty
      ? HistoryTarget(
          provider: HistoryProvider.coingecko,
          query: market.index.symbol,
          symbol: market.index.label,
          name: market.name,
          currency: 'USD',
        )
      : HistoryTarget(
          provider: HistoryProvider.yahoo,
          query: market.index.symbol,
          symbol: market.index.label,
          name: market.name,
          currency: market.currency,
        );

  /// A stock the user searched for and added. The queryable id came from the
  /// search result and was stored with it, so this resolves without guessing —
  /// the same rule [forSymbol] enforces for curated rows.
  static HistoryTarget fromSaved(MarketConfig market, SavedStock stock) =>
      HistoryTarget(
        provider: stock.provider == 'coingecko'
            ? HistoryProvider.coingecko
            : HistoryProvider.yahoo,
        query: stock.query,
        symbol: stock.symbol,
        name: stock.name,
        currency: stock.provider == 'coingecko' ? 'USD' : market.currency,
      );

  /// Resolve a symbol shown in a market's tables (mover / leader / watch) to a
  /// queryable target. Returns null when the symbol isn't in that market's
  /// config — the caller then treats the instrument as having no history rather
  /// than guessing a ticker.
  static HistoryTarget? forSymbol(MarketConfig market, String symbol) {
    final key = symbol.toUpperCase();

    for (final coin in market.coins) {
      if (coin.symbol.toUpperCase() == key) {
        return HistoryTarget(
          provider: HistoryProvider.coingecko,
          query: coin.id,
          symbol: coin.symbol,
          name: coin.name,
          currency: 'USD',
        );
      }
    }

    for (final ref in [...market.movers, ...market.leaders, ...market.watch]) {
      if (ref.symbol.toUpperCase() == key) {
        return HistoryTarget(
          provider: HistoryProvider.yahoo,
          query: ref.yahooTicker,
          symbol: ref.symbol,
          name: ref.name,
          currency: market.currency,
        );
      }
    }

    return null;
  }
}

/// The one place a price curve is fetched, for any instrument and any window.
///
/// Same shape as the rest of `services/`: it routes to an adapter, respects
/// [DataPolicy] (Yahoo goes through the proxy on Web), and returns the
/// normalized model. Reuse it anywhere a chart is needed — the details dialog,
/// a market's headline index, a future watchlist chart — by handing it a
/// [HistoryTarget].
///
/// **It never falls back to mock.** A source that has nothing, is blocked, or
/// throws yields `null`, and the caller renders "N.A.". A drawn line here would
/// be read as a real price, which is exactly what a mock must not do.
class PriceHistoryService {
  final DataPolicy policy;

  const PriceHistoryService({this.policy = const DataPolicy()});

  /// Proxy base for a source, or null to call it directly.
  String? _proxyFor(DataSource s) =>
      policy.modeFor(s) == SourceMode.proxy ? policy.proxyBaseUrl : null;

  /// Whether this platform can serve [target] at all — lets a caller hide an
  /// affordance instead of opening a view that can only say "N.A.".
  bool canServe(HistoryTarget target) => switch (target.provider) {
    HistoryProvider.coingecko => policy.isLive(DataSource.coingecko),
    HistoryProvider.yahoo => policy.isLive(DataSource.yahoo),
  };

  /// The curve for [target] over [range], or null when it isn't available.
  /// Results are cached per (instrument, range) inside the adapters.
  Future<PriceHistory?> fetch(HistoryTarget target, HistoryRange range) async {
    if (!canServe(target)) return null;
    try {
      final points = switch (target.provider) {
        HistoryProvider.coingecko =>
          await CoinGeckoSource.fetchSeries(target.query, range),
        HistoryProvider.yahoo => await YahooSource.fetchSeries(
          target.query,
          range,
          proxyBase: _proxyFor(DataSource.yahoo),
        ),
      };
      // One point is a dot, not a curve — treat it as nothing to show.
      if (points.length < 2) return null;
      return PriceHistory(
        symbol: target.symbol,
        name: target.name,
        range: range,
        points: points,
        currency: target.currency,
        source: target.provider == HistoryProvider.coingecko
            ? 'CoinGecko'
            : 'Yahoo',
      );
    } catch (_) {
      return null; // N.A. — never a fabricated series.
    }
  }
}
