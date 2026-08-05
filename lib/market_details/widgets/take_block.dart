import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/common.dart';

/// The per-market AI Take: a short read on the market, its sentiment, and the
/// sources it was grounded on. Informational only — never advice.
class TakeBlock extends StatelessWidget {
  final String marketName;
  final Take take;

  const TakeBlock({super.key, required this.marketName, required this.take});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg - 1),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                TablerIcons.sparkles,
                size: AppIconSize.inline - 2,
                color: AppColors.accent,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'AI Take · $marketName',
                  overflow: TextOverflow.ellipsis,
                  style: AppText.titleSmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SentimentTag(take.sentiment),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(take.text, style: AppText.body.copyWith(
            color: AppColors.ink2,
            height: 1.55,
          )),
          if (take.citations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs + 2,
              runSpacing: AppSpacing.xs + 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('SOURCES', style: AppText.label.copyWith(fontSize: 10)),
                for (final c in take.citations) InfoChip(c),
                const InfoChip('+ web'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SentimentTag extends StatelessWidget {
  final Sentiment sentiment;
  const _SentimentTag(this.sentiment);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.tint(sentiment.color),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(sentiment.icon, size: 12, color: sentiment.color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          sentiment.label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: sentiment.color,
          ),
        ),
      ],
    ),
  );
}
