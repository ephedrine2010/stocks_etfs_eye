import 'package:equatable/equatable.dart';

/// The timeline windows a price curve can be drawn over. One enum drives the
/// pills in the UI, the Yahoo `range`/`interval` pair, the CoinGecko `days`
/// value and the cache TTL — add a window here and every layer follows.
enum HistoryRange {
  day('1D', 'Day', yahooRange: '1d', yahooInterval: '5m', coinDays: 1),
  week('1W', 'Week', yahooRange: '5d', yahooInterval: '30m', coinDays: 7),
  month('1M', 'Month', yahooRange: '1mo', yahooInterval: '1d', coinDays: 30),
  months3('3M', '3 months', yahooRange: '3mo', yahooInterval: '1d', coinDays: 90),
  months6('6M', '6 months', yahooRange: '6mo', yahooInterval: '1d', coinDays: 180);

  /// Pill label, e.g. "3M".
  final String label;

  /// Spoken form for tooltips / captions, e.g. "3 months".
  final String longLabel;

  final String yahooRange;
  final String yahooInterval;
  final int coinDays;

  const HistoryRange(
    this.label,
    this.longLabel, {
    required this.yahooRange,
    required this.yahooInterval,
    required this.coinDays,
  });

  /// True when the series is finer than one point per day — the axis then shows
  /// clock times instead of dates.
  bool get isIntraday => yahooInterval != '1d';

  /// Intraday windows go stale in a minute; daily ones hold for the quarter-hour
  /// (same tiers the quote/leaders caches use).
  Duration get ttl =>
      isIntraday ? const Duration(seconds: 60) : const Duration(minutes: 15);
}

/// One point on a price curve.
class PricePoint extends Equatable {
  final DateTime time;
  final double close;

  const PricePoint(this.time, this.close);

  @override
  List<Object?> get props => [time, close];
}

/// A resolved price curve for one instrument over one [HistoryRange].
///
/// Only ever built from real source data — there is no mock history. When a
/// source has nothing for an instrument the service returns null and the UI
/// says "N.A." rather than drawing an invented line.
class PriceHistory extends Equatable {
  final String symbol;
  final String name;
  final HistoryRange range;
  final List<PricePoint> points;
  final String currency;

  /// Which adapter answered — shown in the chip strip, like the quote's.
  final String source;

  const PriceHistory({
    required this.symbol,
    required this.name,
    required this.range,
    required this.points,
    required this.currency,
    required this.source,
  });

  double get first => points.first.close;
  double get last => points.last.close;
  double get min => points.map((p) => p.close).reduce((a, b) => a < b ? a : b);
  double get max => points.map((p) => p.close).reduce((a, b) => a > b ? a : b);

  /// Change across the window itself (not the daily change) — null when the
  /// opening value is zero, so the caller shows "—" instead of a fake 0%.
  double? get changePct => first == 0 ? null : ((last - first) / first) * 100;

  @override
  List<Object?> get props => [symbol, range, points, currency, source];
}
