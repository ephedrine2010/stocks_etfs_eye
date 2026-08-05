import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../data/models/models.dart';
import '../shared/widgets/common.dart';
import '../shared/widgets/sparkline.dart';
import '../shared/widgets/surfaces.dart';
import 'cubit/market_details_cubit.dart';
import 'widgets/leaders_table.dart';
import 'widgets/movers_table.dart';
import 'widgets/news_list.dart';
import 'widgets/take_block.dart';

/// Open one market's details over the page. The cubit — and its clock — live
/// exactly as long as the dialog does.
Future<void> showMarketDetails(BuildContext context, Market market) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => BlocProvider(
      create: (_) => MarketDetailsCubit(market),
      child: const MarketDetailsDialog(),
    ),
  );
}

/// The market details dialog: header → chart → AI Take → leading stocks →
/// top movers → news & sentiment.
///
/// It closes from the top-left `X`, always in the same place.
class MarketDetailsDialog extends StatelessWidget {
  const MarketDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketDetailsCubit, MarketDetailsState>(
      builder: (context, state) {
        return Dialog(
          insetPadding: const EdgeInsets.all(AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.line),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(state: state),
                const Divider(height: 1, color: AppColors.line),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: _Body(state: state),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final MarketDetailsState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final m = state.market;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(TablerIcons.x, size: AppIconSize.standard),
            color: AppColors.ink2,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(m.flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    m.indexLabel,
                    style: AppText.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${m.name} · ${m.city}',
                  style: AppText.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Fmt.price(m.quote.price),
                  style: AppText.numHeadline.copyWith(fontSize: 22),
                ),
                ChangeText(m.quote.changePct, big: true, fontSize: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final MarketDetailsState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    final m = state.market;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusStrip(state: state),
        const SizedBox(height: AppSpacing.lg),
        Sparkline(data: m.spark, changePct: m.quote.changePct, height: 90),
        if (state.hasTake) ...[
          const SizedBox(height: AppSpacing.xl),
          TakeBlock(marketName: m.name, take: m.take!),
        ],
        if (state.hasLeaders) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionLabel('Leading stocks · ${m.currency}'),
          const SizedBox(height: AppSpacing.xs + 2),
          LeadersTable(leaders: m.leaders),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionLabel('Top movers · session'),
        const SizedBox(height: AppSpacing.xs + 2),
        if (state.hasMovers)
          MoversTable(movers: m.movers)
        else
          const EmptyState(
            icon: TablerIcons.chart_bar_off,
            title: 'No movers for this session',
            hint: 'They appear once the market has traded.',
          ),
        const SizedBox(height: AppSpacing.xl),
        const SectionLabel('Latest · news & sentiment'),
        const SizedBox(height: AppSpacing.xs + 2),
        if (state.hasNews)
          NewsList(items: m.news)
        else
          const EmptyState(
            icon: TablerIcons.news_off,
            title: 'No headlines for this market yet',
            hint: 'A news feed for this exchange is still to be wired up.',
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Headlines, sentiment and any AI text are informational only — '
          'not investment advice.',
          style: AppText.caption,
        ),
      ],
    );
  }
}

/// Open/closed, the market's own clock, and which source answered.
class _StatusStrip extends StatelessWidget {
  final MarketDetailsState state;
  const _StatusStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    final m = state.market;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusPill(open: state.isOpen),
        InfoChip('${state.clockLabel} ${state.localClock}'),
        InfoChip('Source · ${m.quote.source}'),
        InfoChip(m.currency),
      ],
    );
  }
}
