import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/i18n.dart';
import '../../app/theme.dart';

/// Uppercase section label — the old `.lbl`.
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  const SectionLabel(this.text, {super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(text.toUpperCase(), style: AppText.label),
  );
}

/// Colored, tabular signed-percent text (gain green / loss red).
class ChangeText extends StatelessWidget {
  final double changePct;
  final bool big; // headline "+0.62%" vs compact "+2.1%"
  final double? fontSize;

  const ChangeText(this.changePct, {super.key, this.big = false, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final s = big ? Fmt.signedPct(changePct) : Fmt.compactPct(changePct);
    return Text(
      s,
      style: AppText.mono.copyWith(
        color: Fmt.gainLoss(changePct),
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A small rounded pill (used for source/city chips).
class InfoChip extends StatelessWidget {
  final String text;
  final Color? color;
  const InfoChip(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color ?? AppColors.line),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10.5, color: color ?? AppColors.ink2),
    ),
  );
}

/// Open/closed status pill with a pulsing dot when open.
class StatusPill extends StatelessWidget {
  final bool open;
  const StatusPill({super.key, required this.open});

  @override
  Widget build(BuildContext context) {
    final color = open ? AppColors.gain : AppColors.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: color, pulse: open),
          const SizedBox(width: 5),
          Text(
            open ? context.s.open : context.s.closed,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _Dot({required this.color, required this.pulse});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.pulse && _c.isAnimating) {
      _c.stop();
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (!widget.pulse) return dot;
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.35).animate(_c),
      child: dot,
    );
  }
}

/// Small sentiment glyph (tabler icon) in its sentiment color.
class SentimentIcon extends StatelessWidget {
  final Sentiment sentiment;
  final double size;
  const SentimentIcon(this.sentiment, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) =>
      Icon(sentiment.icon, size: size, color: sentiment.color);
}
