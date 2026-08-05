import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/models.dart';
import 'screen_all_markets_state.dart';

export 'screen_all_markets_state.dart';

/// Owns the cross-market screener: it flattens every market's movers + leaders
/// into one list and applies the sort, the gain/loss filter, the market filter
/// and the search.
///
/// It reuses the live data the dashboard already fetched — no extra API calls.
class ScreenAllMarketsCubit extends Cubit<ScreenAllMarketsState> {
  ScreenAllMarketsCubit({List<Market> markets = const []})
    : super(const ScreenAllMarketsState()) {
    setMarkets(markets);
  }

  /// Feed in fresh markets after a dashboard load/refresh; filters are kept.
  void setMarkets(List<Market> markets) => _apply(state, markets: markets);

  /// Tapping a column header sorts by it; tapping the active one flips it.
  void sortBy(ScreenerSort sort) => _apply(
    state,
    sort: sort,
    ascending: state.sort == sort ? !state.ascending : sort.ascendingByDefault,
  );

  void setChangeFilter(ChangeFilter filter) =>
      _apply(state, changeFilter: filter);

  /// [id] null ⇒ all markets.
  void setMarketFilter(String? id) => _apply(state, marketId: id, clearMarket: id == null);

  void search(String query) => _apply(state, query: query);

  void clearFilters() => _apply(
    state,
    changeFilter: ChangeFilter.all,
    query: '',
    clearMarket: true,
  );

  void _apply(
    ScreenAllMarketsState s, {
    List<Market>? markets,
    ScreenerSort? sort,
    bool? ascending,
    ChangeFilter? changeFilter,
    String? query,
    String? marketId,
    bool clearMarket = false,
  }) {
    final next = ScreenAllMarketsState(
      markets: markets ?? s.markets,
      sort: sort ?? s.sort,
      ascending: ascending ?? s.ascending,
      changeFilter: changeFilter ?? s.changeFilter,
      query: query ?? s.query,
      marketId: clearMarket ? null : (marketId ?? s.marketId),
    );
    final all = _flatten(next.markets);
    final rows = _sorted(_filtered(all, next), next);
    // Equatable dedupes an identical state for us, so just emit.
    emit(
      ScreenAllMarketsState(
        markets: next.markets,
        rows: rows,
        totalCount: all.length,
        sort: next.sort,
        ascending: next.ascending,
        changeFilter: next.changeFilter,
        query: next.query,
        marketId: next.marketId,
      ),
    );
  }

  /// Flatten markets → rows, de-duped by market+symbol. Leaders win over movers
  /// on collision (they carry price + dividend); movers fill the rest.
  List<ScreenerRow> _flatten(List<Market> markets) {
    final map = <String, ScreenerRow>{};
    for (var i = 0; i < markets.length; i++) {
      final m = markets[i];
      for (final l in m.leaders) {
        map['${m.id}:${l.symbol}'] = ScreenerRow(
          order: i,
          flag: m.flag,
          marketId: m.id,
          symbol: l.symbol,
          name: l.name,
          price: l.price,
          changePct: l.changePct,
          divYield: l.dividend?.yield,
        );
      }
      for (final mv in m.movers) {
        map.putIfAbsent(
          '${m.id}:${mv.symbol}',
          () => ScreenerRow(
            order: i,
            flag: m.flag,
            marketId: m.id,
            symbol: mv.symbol,
            name: mv.name,
            price: mv.price,
            changePct: mv.changePct,
            divYield: null,
          ),
        );
      }
    }
    return map.values.toList();
  }

  List<ScreenerRow> _filtered(
    List<ScreenerRow> rows,
    ScreenAllMarketsState s,
  ) {
    final q = s.query.trim().toLowerCase();
    return rows.where((r) {
      if (s.marketId != null && r.marketId != s.marketId) return false;
      if (s.changeFilter == ChangeFilter.gainers && r.changePct < 0) {
        return false;
      }
      if (s.changeFilter == ChangeFilter.losers && r.changePct >= 0) {
        return false;
      }
      if (q.isNotEmpty &&
          !r.symbol.toLowerCase().contains(q) &&
          !r.name.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<ScreenerRow> _sorted(
    List<ScreenerRow> rows,
    ScreenAllMarketsState s,
  ) {
    int dir(int c) => s.ascending ? c : -c;

    /// Nulls always sort last, independent of direction.
    int nullable(num? x, num? y) {
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return dir(x.compareTo(y));
    }

    rows.sort((a, b) => switch (s.sort) {
      ScreenerSort.market => dir(a.order.compareTo(b.order)),
      ScreenerSort.ticker => dir(a.symbol.compareTo(b.symbol)),
      ScreenerSort.name => dir(
        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ),
      ScreenerSort.change => dir(a.changePct.compareTo(b.changePct)),
      ScreenerSort.price => nullable(a.price, b.price),
      ScreenerSort.dividend => nullable(a.divYield, b.divYield),
    });
    return rows;
  }
}
