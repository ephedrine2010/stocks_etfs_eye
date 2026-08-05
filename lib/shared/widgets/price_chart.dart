import 'package:flutter/material.dart';
// `intl` also exports a TextDirection — hide it so the painter keeps Flutter's.
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import 'common.dart';

/// A full price curve with a scrubbing crosshair — the grown-up sibling of
/// [Sparkline], which stays a decorative 14-point mark.
///
/// Reusable for any [PriceHistory]: an instrument, a headline index, a
/// watchlist row. It draws only the points it is given; a gap in the data is a
/// gap in the line, never an interpolated guess.
class PriceChart extends StatefulWidget {
  final PriceHistory history;
  final double height;

  const PriceChart({super.key, required this.history, this.height = 176});

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  /// Point under the pointer, or null when nothing is being scrubbed.
  int? _cursor;

  @override
  void didUpdateWidget(covariant PriceChart old) {
    super.didUpdateWidget(old);
    // A new series invalidates the old index — drop it rather than let it point
    // into a shorter list.
    if (old.history != widget.history) _cursor = null;
  }

  void _scrub(Offset local, double width) {
    final n = widget.history.points.length;
    final ratio = (local.dx / width).clamp(0.0, 1.0);
    final i = (ratio * (n - 1)).round().clamp(0, n - 1);
    if (i != _cursor) setState(() => _cursor = i);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.history;
    final points = h.points;
    final cursor = _cursor;
    final shown = cursor == null ? points.last : points[cursor];
    final color = Fmt.gainLoss(h.changePct ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Readout(history: h, point: shown, scrubbing: cursor != null),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return MouseRegion(
              onHover: (e) => _scrub(e.localPosition, width),
              onExit: (_) => setState(() => _cursor = null),
              child: GestureDetector(
                onTapDown: (d) => _scrub(d.localPosition, width),
                onHorizontalDragUpdate: (d) => _scrub(d.localPosition, width),
                onHorizontalDragEnd: (_) => setState(() => _cursor = null),
                child: SizedBox(
                  height: widget.height,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _CurvePainter(
                      history: h,
                      color: color,
                      cursor: cursor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_axisStamp(points.first.time, h.range), style: AppText.caption),
            Text(_axisStamp(points.last.time, h.range), style: AppText.caption),
          ],
        ),
      ],
    );
  }
}

/// The value the crosshair is on (or the latest close when idle), plus the
/// window's own change — so "3M" reads as the 3-month move, not today's.
class _Readout extends StatelessWidget {
  final PriceHistory history;
  final PricePoint point;
  final bool scrubbing;

  const _Readout({
    required this.history,
    required this.point,
    required this.scrubbing,
  });

  @override
  Widget build(BuildContext context) {
    final change = history.changePct;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(Fmt.price(point.close), style: AppText.numHeadline),
        const SizedBox(width: AppSpacing.xs + 2),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(history.currency, style: AppText.caption),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (change != null)
              ChangeText(change, big: true)
            else
              Text('—', style: AppText.mono.copyWith(color: AppColors.ink3)),
            const SizedBox(height: 2),
            Text(
              scrubbing
                  ? _readoutStamp(point.time, history.range)
                  : 'over ${history.range.longLabel.toLowerCase()}',
              style: AppText.caption,
            ),
          ],
        ),
      ],
    );
  }
}

/// Axis tick: a clock time for intraday windows, a date for daily ones.
String _axisStamp(DateTime t, HistoryRange range) =>
    DateFormat(range.isIntraday ? 'HH:mm' : 'd MMM').format(t);

/// The scrubbed point always names its day too — "12 Mar 14:30" — so an
/// intraday reading can't be mistaken for a different session.
String _readoutStamp(DateTime t, HistoryRange range) =>
    DateFormat(range.isIntraday ? 'd MMM HH:mm' : 'd MMM y').format(t);

class _CurvePainter extends CustomPainter {
  final PriceHistory history;
  final Color color;
  final int? cursor;

  _CurvePainter({required this.history, required this.color, this.cursor});

  /// Room on the right for the min/max value labels.
  static const _gutter = 52.0;
  static const _pad = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final points = history.points;
    if (points.length < 2) return;

    final min = history.min;
    final max = history.max;
    final span = (max - min).abs() < 1e-9 ? 1.0 : (max - min);

    final plotW = size.width - _gutter;
    final plotH = size.height - _pad * 2;
    final dx = plotW / (points.length - 1);

    Offset at(int i) => Offset(
      dx * i,
      _pad + (1 - (points[i].close - min) / span) * plotH,
    );

    // Guides at the window's high, midpoint and low — the only horizontal rules.
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.line;
    for (final (level, value) in [(0.0, max), (0.5, (max + min) / 2), (1.0, min)]) {
      final y = _pad + level * plotH;
      canvas.drawLine(Offset(0, y), Offset(plotW, y), guide);
      _label(canvas, Fmt.price(value), Offset(plotW + AppSpacing.sm, y - 6));
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final p = at(i);
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      Path.from(path)
        ..lineTo(plotW, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, plotW, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    final i = cursor;
    if (i != null && i >= 0 && i < points.length) {
      final p = at(i);
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, size.height),
        Paint()
          ..strokeWidth = 1
          ..color = AppColors.lineHover,
      );
      canvas.drawCircle(p, 3.5, Paint()..color = color);
      canvas.drawCircle(
        p,
        3.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.surface,
      );
    }
  }

  void _label(Canvas canvas, String text, Offset at) {
    TextPainter(
      text: TextSpan(text: text, style: AppText.caption.copyWith(fontSize: 10)),
      textDirection: TextDirection.ltr,
    )
      ..layout(maxWidth: _gutter)
      ..paint(canvas, at);
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.history != history || old.color != color || old.cursor != cursor;
}
