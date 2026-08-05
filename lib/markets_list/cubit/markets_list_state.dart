import 'package:equatable/equatable.dart';

import '../../data/models/models.dart';

/// Which markets the list shows.
enum MarketFilter {
  all('All'),
  open('Open'),
  closed('Closed');

  final String label;
  const MarketFilter(this.label);
}

/// A market plus the status derived from the clock at this instant. The tile is
/// dumb — everything time-dependent is computed once per tick in the cubit.
class MarketStatus extends Equatable {
  final Market market;
  final bool isOpen;

  /// The market's own wall clock, "HH:mm:ss".
  final String localClock;

  const MarketStatus({
    required this.market,
    required this.isOpen,
    required this.localClock,
  });

  String get id => market.id;

  @override
  List<Object?> get props => [market, isOpen, localClock];
}

class MarketsListState extends Equatable {
  /// Every tracked market with its live status, in config order.
  final List<MarketStatus> statuses;
  final MarketFilter filter;

  /// The instant this state was built. Also drives the home top bar's UTC clock,
  /// so the whole page ticks off one timer.
  final DateTime now;

  const MarketsListState({
    required this.statuses,
    required this.filter,
    required this.now,
  });

  MarketsListState.empty()
    : statuses = const [],
      filter = MarketFilter.all,
      now = DateTime.now();

  List<MarketStatus> get visible => switch (filter) {
    MarketFilter.all => statuses,
    MarketFilter.open => statuses.where((s) => s.isOpen).toList(),
    MarketFilter.closed => statuses.where((s) => !s.isOpen).toList(),
  };

  int get openCount => statuses.where((s) => s.isOpen).length;
  int get total => statuses.length;

  /// Count for a filter's pill, so the user sees what a filter would leave.
  int countFor(MarketFilter f) => switch (f) {
    MarketFilter.all => total,
    MarketFilter.open => openCount,
    MarketFilter.closed => total - openCount,
  };

  @override
  List<Object?> get props => [statuses, filter, now];
}
