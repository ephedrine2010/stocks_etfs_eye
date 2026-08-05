import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/models.dart';
import '../../services/my_stocks_service.dart';

class StockSearchState extends Equatable {
  final String query;
  final List<SavedStock> results;
  final bool searching;

  /// A search has finished for the current query — the difference between
  /// "nothing found" and "nothing typed yet", which the empty state needs.
  final bool searched;

  const StockSearchState({
    this.query = '',
    this.results = const [],
    this.searching = false,
    this.searched = false,
  });

  StockSearchState copyWith({
    String? query,
    List<SavedStock>? results,
    bool? searching,
    bool? searched,
  }) => StockSearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    searching: searching ?? this.searching,
    searched: searched ?? this.searched,
  );

  @override
  List<Object?> get props => [query, results, searching, searched];
}

/// Drives the "add a stock" search box for one market.
///
/// Debounced: a request goes out when typing pauses, not once per keystroke —
/// both sources are free tiers and neither should be hit that hard.
class StockSearchCubit extends Cubit<StockSearchState> {
  final MyStocksService service;
  final MarketConfig market;

  Timer? _debounce;

  /// Guards against a slow earlier query landing after a faster later one.
  int _request = 0;

  StockSearchCubit({required this.service, required this.market})
    : super(const StockSearchState());

  static const _minChars = 2;
  static const _debounceFor = Duration(milliseconds: 350);

  void search(String query) {
    _debounce?.cancel();
    final q = query.trim();

    if (q.length < _minChars) {
      _request++; // strand any in-flight result
      emit(
        StockSearchState(query: q),
      );
      return;
    }

    emit(state.copyWith(query: q, searching: true, searched: false));
    _debounce = Timer(_debounceFor, () => _run(q));
  }

  Future<void> _run(String query) async {
    final token = ++_request;
    final results = await service.search(market, query);
    if (isClosed || token != _request) return;
    emit(
      state.copyWith(results: results, searching: false, searched: true),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
