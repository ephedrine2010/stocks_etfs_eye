import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Ticks once per second. The emitted [DateTime] is the current instant; the UI
/// derives the UTC clock and each market's local time / open-closed from it
/// (via `MarketHours`), so tiles tick without any server round-trip — mirroring
/// the old client-side `marketHours.js` behaviour.
class ClockCubit extends Cubit<DateTime> {
  Timer? _timer;

  ClockCubit() : super(DateTime.now()) {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => emit(DateTime.now()),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
