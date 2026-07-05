import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/schedule.dart';

/// Per-market open/closed + local time, ported from the old `marketHours.js`.
/// Uses the IANA tz database (via the `timezone` package) so DST is handled
/// correctly — the Dart equivalent of the browser's `Intl` timezone support.
abstract class MarketHours {
  static bool _initialized = false;

  /// Load the tz database once. Safe to call repeatedly.
  static void ensureInitialized() {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    _initialized = true;
  }

  static tz.TZDateTime _now(String timezone) {
    ensureInitialized();
    final location = tz.getLocation(timezone);
    return tz.TZDateTime.now(location);
  }

  /// Local parts for a market: weekday (0=Sun…6=Sat), minutes-since-midnight,
  /// and an "HH:mm:ss" clock string.
  static LocalParts localParts(String timezone) {
    final t = _now(timezone);
    // Dart weekday: Mon=1…Sun=7. Convert to JS convention Sun=0…Sat=6.
    final weekday = t.weekday % 7;
    final minutes = t.hour * 60 + t.minute;
    String two(int n) => n.toString().padLeft(2, '0');
    return LocalParts(
      weekday: weekday,
      minutes: minutes,
      time: '${two(t.hour)}:${two(t.minute)}:${two(t.second)}',
    );
  }

  /// Whether a market is currently open, per its schedule.
  static bool isOpen(Schedule schedule) {
    if (schedule.always) return true;
    final p = localParts(schedule.tz);
    if (!schedule.days.contains(p.weekday)) return false;
    return schedule.sessions.any((s) => p.minutes >= s[0] && p.minutes < s[1]);
  }

  /// The ticking local-time label for a market's tile.
  static String localClock(String timezone) => localParts(timezone).time;
}

class LocalParts {
  final int weekday;
  final int minutes;
  final String time;

  const LocalParts({
    required this.weekday,
    required this.minutes,
    required this.time,
  });
}
