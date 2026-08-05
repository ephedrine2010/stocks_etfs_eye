import 'package:equatable/equatable.dart';

import '../../data/models/models.dart';

/// What the screener is sorted by. Maps 1:1 to the tappable column headers.
enum ScreenerSort {
  market('Mkt'),
  ticker('Ticker'),
  name('Company'),
  price('Price'),
  change('Chg'),
  dividend('Div');

  final String header;
  const ScreenerSort(this.header);

  /// Text columns read best A→Z; numeric columns high→low.
  bool get ascendingByDefault =>
      this == ScreenerSort.market ||
      this == ScreenerSort.ticker ||
      this == ScreenerSort.name;
}

/// Gain/loss quick filter.
enum ChangeFilter {
  all('All'),
  gainers('Gainers'),
  losers('Losers');

  final String label;
  const ChangeFilter(this.label);
}

/// One flattened instrument row — a market's mover or leader, lifted out of its
/// market so instruments from all 7 can be ranked against each other.
class ScreenerRow extends Equatable {
  final int order; // market display order, for the "Mkt" sort
  final String flag;
  final String marketId;
  final String symbol;
  final String name;
  final double? price;
  final double changePct;
  final double? divYield;

  const ScreenerRow({
    required this.order,
    required this.flag,
    required this.marketId,
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePct,
    required this.divYield,
  });

  @override
  List<Object?> get props => [marketId, symbol, name, price, changePct, divYield];
}

class ScreenAllMarketsState extends Equatable {
  /// The markets behind the rows — drives the per-market filter pills.
  final List<Market> markets;

  /// Rows after filtering and sorting; what the table renders.
  final List<ScreenerRow> rows;

  /// How many instruments exist before any filter, for the "x of y" count.
  final int totalCount;

  final ScreenerSort sort;
  final bool ascending;
  final ChangeFilter changeFilter;
  final String query;

  /// null ⇒ every market.
  final String? marketId;

  const ScreenAllMarketsState({
    this.markets = const [],
    this.rows = const [],
    this.totalCount = 0,
    this.sort = ScreenerSort.change,
    this.ascending = false, // default: biggest movers first
    this.changeFilter = ChangeFilter.all,
    this.query = '',
    this.marketId,
  });

  /// True when any filter is narrowing the list — lets the UI offer a reset.
  bool get isFiltered =>
      changeFilter != ChangeFilter.all ||
      marketId != null ||
      query.trim().isNotEmpty;

  @override
  List<Object?> get props => [
    markets,
    rows,
    totalCount,
    sort,
    ascending,
    changeFilter,
    query,
    marketId,
  ];
}
