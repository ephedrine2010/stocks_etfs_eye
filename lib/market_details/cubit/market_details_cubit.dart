import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/models.dart';
import '../../services/market_hours.dart';
import 'market_details_state.dart';

export 'market_details_state.dart';

/// Owns one market's details view. Created when the dialog opens and disposed
/// with it, so the ticker only runs while the dialog is on screen.
class MarketDetailsCubit extends Cubit<MarketDetailsState> {
  Timer? _timer;
  Market _market;

  MarketDetailsCubit(Market market)
    : _market = market,
      super(_stateOf(market)) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Swap in a fresher copy of the same market (e.g. after a refresh).
  void setMarket(Market market) {
    _market = market;
    _tick();
  }

  void _tick() => emit(_stateOf(_market));

  static MarketDetailsState _stateOf(Market m) => MarketDetailsState(
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
