import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/models.dart';
import '../../services/my_stocks_service.dart';
import '../../services/my_stocks_store.dart';
import 'my_stocks_state.dart';

export 'my_stocks_state.dart';

/// Owns one market's "My stocks" section. Created with the details dialog and
/// disposed with it, so saved rows are priced only while they're on screen.
///
/// The store is the source of truth; this cubit listens to it, so adding a
/// stock from the search dialog updates the section without either side
/// knowing about the other.
class MyStocksCubit extends Cubit<MyStocksState> {
  final MyStocksStore store;
  final MyStocksService service;
  final MarketConfig market;

  StreamSubscription<void>? _sub;

  /// Guards against an older fetch landing after a newer one and overwriting it.
  int _request = 0;

  MyStocksCubit({
    required this.store,
    required this.service,
    required this.market,
  }) : super(
         MyStocksState(
           saved: store.forMarket(market.id),
           canSearch: service.canSearch(market),
         ),
       ) {
    _sub = store.changes.listen((_) => _refresh());
    _refresh();
  }

  Future<void> _refresh() async {
    final saved = store.forMarket(market.id);
    final token = ++_request;

    if (saved.isEmpty) {
      emit(state.copyWith(saved: const [], rows: const [], loading: false));
      return;
    }

    emit(state.copyWith(saved: saved, loading: true));
    final rows = await service.rows(market, saved);
    if (isClosed || token != _request) return;
    emit(state.copyWith(saved: saved, rows: rows, loading: false));
  }

  /// Returns false when the instrument was already in the list, so the caller
  /// can say so rather than appear to do nothing.
  Future<bool> add(SavedStock stock) => store.add(stock);

  Future<void> remove(SavedStock stock) => store.remove(stock);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
