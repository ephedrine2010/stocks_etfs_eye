import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/common.dart';

/// Latest headlines for a market, each with its sentiment glyph, source and age.
class NewsList extends StatelessWidget {
  final List<NewsItem> items;
  const NewsList({super.key, required this.items});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [for (final n in items) _NewsRow(n)],
  );
}

class _NewsRow extends StatelessWidget {
  final NewsItem item;
  const _NewsRow(this.item);

  @override
  Widget build(BuildContext context) {
    final meta = [
      item.sentiment.label,
      item.source,
      if (item.published != null) '${item.published} ago',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SentimentIcon(item.sentiment, size: 15),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.headline,
                  style: AppText.body.copyWith(
                    decoration: item.hasLink ? TextDecoration.underline : null,
                    decorationColor: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(meta, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
