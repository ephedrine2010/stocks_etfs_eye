import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A compact sparkline, ported from the old inline-SVG `charts.spark`.
/// Colored green/red by the sign of [changePct]; draws a soft area fill under
/// the line. Renders nothing meaningful for fewer than 2 points.
class Sparkline extends StatelessWidget {
  final List<double> data;
  final double changePct;
  final double height;
  final bool area;

  const Sparkline({
    super.key,
    required this.data,
    required this.changePct,
    this.height = 34,
    this.area = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparkPainter(
          data: data,
          color: changePct >= 0 ? AppColors.gain : AppColors.loss,
          area: area,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool area;

  _SparkPainter({required this.data, required this.color, required this.area});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 1e-9 ? 1.0 : (max - min);

    const pad = 2.0;
    final w = size.width;
    final h = size.height - pad * 2;
    final dx = w / (data.length - 1);

    Offset pointAt(int i) {
      final x = dx * i;
      final norm = (data[i] - min) / range; // 0..1, low→bottom
      final y = pad + (1 - norm) * h;
      return Offset(x, y);
    }

    final path = Path()..moveTo(0, pointAt(0).dy);
    for (var i = 1; i < data.length; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
    }

    if (area) {
      final fill = Path.from(path)
        ..lineTo(w, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.data != data || old.color != color || old.area != area;
}
