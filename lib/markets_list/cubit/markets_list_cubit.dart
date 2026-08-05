import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/models.dart';
import '../../services/market_hours.dart';
import 'markets_list_state.dart';

export 'markets_list_state.dart';

/// Owns the "markets — live status" section: the markets it shows, the
/// open/closed filter, and the one-second tick that recomputes each market's
/// status and clock.
///
/// Open/closed is derived client-side from the device clock (the old
/// `marketHours.js` behaviour), so tiles keep ticking between data refreshes —
/// no server round-trip and no re-fetch.
class MarketsListCubit extends Cubit<MarketsListState> {
  Timer? _timer;
  List<Market> _markets;
  MarketFilter _filter = MarketFilter.all;

  MarketsListCubit({List<Market> markets = const []})
    : _markets = markets,
      super(MarketsListState.empty()) {
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Feed in fresh markets after a dashboard load/refresh.
  void setMarkets(List<Market> markets) {
    _markets = markets;
    _tick();
  }

  void setFilter(MarketFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    _tick();
  }

  void _tick() => emit(
    MarketsListState(
      statuses: _markets.map(_statusOf).toList(growable: false),
      filter: _filter,
      now: DateTime.now(),
    ),
  );

  MarketStatus _statusOf(Market m) => MarketStatus(
    market: m,
    isOpen: MarketHours.isOpen(m.schedule),
    localClock: MarketHours.localClock(m.tz),
  );

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
