import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../app/i18n.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import 'common.dart';

/// The AI Morning Brief — a gold-accented roll-up across all markets.
class BriefCard extends StatelessWidget {
  final Brief brief;
  final DateTime asOf;

  const BriefCard({super.key, required this.brief, required this.asOf});

  String _when(Strings s) {
    final d = asOf.toUtc();
    final date = DateFormat('EEE, d MMM yyyy').format(d);
    final time = DateFormat('HH:mm').format(d);
    return s.briefWhen(date, time);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final live = s.liveLabel(brief.source);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentDim),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.07),
            AppColors.surface,
          ],
          stops: const [0, 0.6],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(s),
          const SizedBox(height: 13),
          Text(
            brief.lead.resolve(s.ar),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.ink,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 15),
          _lines(s),
          const SizedBox(height: 15),
          _hint(s),
          const SizedBox(height: 12),
          _citations(s),
          const SizedBox(height: 12),
          Text(
            s.briefAttribution(live),
            style: const TextStyle(fontSize: 11, color: AppColors.ink3),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(Strings s) => Row(
    children: [
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.accentDim),
        ),
        child: const Icon(TablerIcons.sparkles, size: 12, color: AppColors.accent),
      ),
      const SizedBox(width: 9),
      Flexible(
        child: Text(
          s.briefTitle,
          overflow: TextOverflow.ellipsis,
          style: AppText.label.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          _when(s),
          style: const TextStyle(fontSize: 11, color: AppColors.ink3),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _lines(Strings s) => LayoutBuilder(
    builder: (context, c) {
      final twoCol = c.maxWidth > 560;
      final children = brief.lines.map((l) => _line(s, l)).toList();
      if (!twoCol) {
        return Column(children: children);
      }
      final mid = (children.length + 1) ~/ 2;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: children.sublist(0, mid))),
          const SizedBox(width: 26),
          Expanded(child: Column(children: children.sublist(mid))),
        ],
      );
    },
  );

  Widget _line(Strings s, BriefLine l) => Container(
    padding: const EdgeInsets.symmetric(vertical: 5),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.flag, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 9),
        SizedBox(
          width: 46,
          child: Text(
            l.name,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        SentimentIcon(l.sentiment, size: 14),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            l.text.resolve(s.ar),
            style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
          ),
        ),
      ],
    ),
  );

  Widget _hint(Strings s) => Container(
    padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
    decoration: BoxDecoration(
      color: AppColors.accent.withValues(alpha: 0.08),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      border: const Border(
        left: BorderSide(color: AppColors.accent, width: 3),
      ),
    ),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.5),
        children: [
          TextSpan(
            text: s.todaysHint,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: brief.hint.resolve(s.ar)),
        ],
      ),
    ),
  );

  Widget _citations(Strings s) => Wrap(
    spacing: 6,
    runSpacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(s.sources, style: AppText.label.copyWith(fontSize: 10)),
      for (final c in brief.citations) InfoChip(c),
      InfoChip(s.liveWebSearch),
    ],
  );
}
