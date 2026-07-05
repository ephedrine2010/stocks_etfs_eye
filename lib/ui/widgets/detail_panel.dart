import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../app/format.dart';
import '../../app/i18n.dart';
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
    final s = context.s;
    final open = MarketHours.isOpen(market.schedule);
    final change = market.quote.changePct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(s, open, change),
        const SizedBox(height: 16),
        Sparkline(data: market.spark, changePct: change, height: 90),
        if (market.leaders.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionLabel(s.leadingStocks(market.currency)),
          const SizedBox(height: 6),
          LeadersTable(leaders: market.leaders),
        ],
        if (market.take != null) ...[
          const SizedBox(height: 16),
          _TakeBlock(name: market.nameFor(s.ar), take: market.take!),
        ],
        const SizedBox(height: 16),
        SectionLabel(s.topMovers),
        const SizedBox(height: 6),
        MoversTable(movers: market.movers),
        const SizedBox(height: 18),
        SectionLabel(s.latestNews),
        const SizedBox(height: 6),
        ...market.news.map((n) => _NewsRow(n)),
        const SizedBox(height: 12),
        Text(
          s.newsDisclaimer,
          style: const TextStyle(fontSize: 11, color: AppColors.ink3),
        ),
      ],
    );
  }

  Widget _header(Strings s, bool open, double change) => Row(
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
              '${market.nameFor(s.ar)} · ${market.cityFor(s.ar)} · '
              '${open ? s.openNow : s.closedNow} · ${market.quote.source}',
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
    final s = context.s;
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
                  s.aiTake(name),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _sentTag(s, take.sentiment),
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
                Text(s.sources, style: AppText.label.copyWith(fontSize: 10)),
                for (final c in take.citations) InfoChip(c),
                InfoChip(s.plusWeb),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sentTag(Strings str, Sentiment sent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: sent.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(sent.icon, size: 12, color: sent.color),
        const SizedBox(width: 4),
        Text(
          str.sentiment(sent),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: sent.color,
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
    final s = context.s;
    final meta = [
      s.sentiment(item.sentiment),
      item.source,
      if (item.published != null) s.ago(item.published!),
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
