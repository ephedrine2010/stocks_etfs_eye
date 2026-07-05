import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../data/repository/market_hours.dart';
import 'common.dart';
import 'leaders_table.dart';
import 'movers_table.dart';
import 'sparkline.dart';

/// The selected market's detail card:
/// header → chart → AI Take → leading stocks → top movers → news & sentiment.
class DetailPanel extends StatelessWidget {
  final Market market;
  const DetailPanel({super.key, required this.market});

  @override
  Widget build(BuildContext context) {
    final open = MarketHours.isOpen(market.schedule);
    final change = market.quote.changePct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(open, change),
        const SizedBox(height: 16),
        Sparkline(data: market.spark, changePct: change, height: 90),
        if (market.leaders.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionLabel('Leading stocks · ${market.currency}'),
          const SizedBox(height: 6),
          LeadersTable(leaders: market.leaders),
        ],
        if (market.take != null) ...[
          const SizedBox(height: 16),
          _TakeBlock(name: market.name, take: market.take!),
        ],
        const SizedBox(height: 16),
        const SectionLabel('Top movers · session'),
        const SizedBox(height: 6),
        MoversTable(movers: market.movers),
        const SizedBox(height: 18),
        const SectionLabel('Latest · news & sentiment'),
        const SizedBox(height: 6),
        ...market.news.map((n) => _NewsRow(n)),
        const SizedBox(height: 12),
        const Text(
          'Headlines and sentiment are informational only — not investment advice.',
          style: TextStyle(fontSize: 11, color: AppColors.ink3),
        ),
      ],
    );
  }

  Widget _header(bool open, double change) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(market.flag, style: const TextStyle(fontSize: 26)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              market.indexLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            InfoChip(
              '${market.name} · ${market.city} · '
              '${open ? 'Open now' : 'Closed'} · ${market.quote.source}',
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Fmt.price(market.quote.price),
            style: AppText.mono.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          ChangeText(change, big: true, fontSize: 13),
        ],
      ),
    ],
  );
}

class _TakeBlock extends StatelessWidget {
  final String name;
  final Take take;
  const _TakeBlock({required this.name, required this.take});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(TablerIcons.sparkles, size: 14, color: AppColors.accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'AI Take · $name',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _sentTag(take.sentiment),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            take.text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.ink2,
              height: 1.55,
            ),
          ),
          if (take.citations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
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

  Widget _sentTag(Sentiment s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: s.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(s.icon, size: 12, color: s.color),
        const SizedBox(width: 4),
        Text(
          s.label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: s.color,
          ),
        ),
      ],
    ),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.headline,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.4,
                    decoration: item.hasLink ? TextDecoration.underline : null,
                    decorationColor: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
