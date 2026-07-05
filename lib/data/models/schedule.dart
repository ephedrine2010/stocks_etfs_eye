import 'package:equatable/equatable.dart';

/// A market's trading schedule, ported from the old `schedule` object:
/// `{ tz, days:[0-6], sessions:[[startMin,endMin]], always?, commodity? }`
/// where 0=Sun…6=Sat and minutes are minutes-since-local-midnight.
class Schedule extends Equatable {
  final String tz;
  final List<int> days;
  final List<List<int>> sessions;

  /// Crypto — never closes (24/7).
  final bool always;

  /// Gold — a commodity, ~24h on weekdays (drives the "Trades … UTC" label).
  final bool commodity;

  const Schedule({
    required this.tz,
    required this.days,
    required this.sessions,
    this.always = false,
    this.commodity = false,
  });

  @override
  List<Object?> get props => [tz, days, sessions, always, commodity];
}
