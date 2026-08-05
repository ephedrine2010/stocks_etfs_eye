import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/models.dart';
import '../../services/price_history_service.dart';

/// One instrument's curve and which window it is showing.
///
/// `history == null` while `!loading` means the source had nothing for this
/// instrument and window — the view says "N.A.". There is no mock series.
class InstrumentChartState extends Equatable {
  final HistoryTarget target;
  final HistoryRange range;
  final PriceHistory? history;
  final bool loading;

  const InstrumentChartState({
    required this.target,
    required this.range,
    this.history,
    this.loading = false,
  });

  bool get hasCurve => history != null;

  InstrumentChartState copyWith({
    HistoryRange? range,
    PriceHistory? history,
    bool? loading,
  }) => InstrumentChartState(
    target: target,
    range: range ?? this.range,
    // Explicitly nullable: a window with no data must clear the previous curve,
    // not keep showing the last one under a new label.
    history: history,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [target.query, range, history, loading];
}

/// Drives the instrument chart: pick a window, fetch it, show it or say N.A.
/// Created with the chart dialog and disposed with it.
class InstrumentChartCubit extends Cubit<InstrumentChartState> {
  final PriceHistoryService _service;

  InstrumentChartCubit(
    this._service,
    HistoryTarget target, {
    HistoryRange initial = HistoryRange.month,
  }) : super(InstrumentChartState(target: target, range: initial, loading: true));

  /// Load the current window. Also the retry path after a failed fetch.
  Future<void> load() => select(state.range);

  Future<void> select(HistoryRange range) async {
    if (isClosed) return;
    emit(state.copyWith(range: range, loading: true));
    final history = await _service.fetch(state.target, range);
    if (isClosed) return;
    // A slower earlier window must not overwrite the one now selected.
    if (state.range != range) return;
    emit(state.copyWith(history: history, loading: false));
  }
}
