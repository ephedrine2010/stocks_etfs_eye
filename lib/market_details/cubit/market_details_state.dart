import 'package:equatable/equatable.dart';

import '../../data/models/models.dart';

/// Everything the details dialog renders for one market, with the time-dependent
/// parts already resolved for this tick.
class MarketDetailsState extends Equatable {
  final Market market;
  final bool isOpen;

  /// The market's own wall clock, "HH:mm:ss".
  final String localClock;

  const MarketDetailsState({
    required this.market,
    required this.isOpen,
    required this.localClock,
  });

  bool get hasTake => market.take != null;
  bool get hasLeaders => market.leaders.isNotEmpty;
  bool get hasMovers => market.movers.isNotEmpty;
  bool get hasNews => market.news.isNotEmpty;

  /// The clock label a market wants: crypto trades 24/7, gold ~24h on weekdays,
  /// everything else keeps its exchange-local time.
  String get clockLabel => market.always
      ? '24/7'
      : market.commodity
      ? 'Trades'
      : 'Local time';

  @override
  List<Object?> get props => [market, isOpen, localClock];
}
