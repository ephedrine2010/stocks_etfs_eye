import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../auth/widgets/sign_in_banner.dart';
import '../data/models/models.dart';
import '../services/dashboard_repository.dart';
import '../services/my_stocks_store.dart';
import '../services/price_history_service.dart';
import '../shared/widgets/common.dart';
import '../shared/widgets/controls.dart';
import '../shared/widgets/sparkline.dart';
import '../shared/widgets/surfaces.dart';
import 'cubit/market_details_cubit.dart';
import 'cubit/my_stocks_cubit.dart';
import 'widgets/add_stock_dialog.dart';
import 'widgets/instrument_chart_dialog.dart';
import 'widgets/leaders_table.dart';
import 'widgets/movers_table.dart';
import 'widgets/my_stocks_table.dart';
import 'widgets/news_list.dart';
import 'widgets/take_block.dart';

/// Open one market's details over the page. The cubits — and the clock — live
/// exactly as long as the dialog does, so neither the tick nor the saved-row
/// price fetches outlive the view.
Future<void> showMarketDetails(BuildContext context, Market market) {
  final repository = context.read<DashboardRepository>();
  final store = context.read<MyStocksStore>();
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MarketDetailsCubit(market)),
        BlocProvider(
          create: (_) => MyStocksCubit(
            store: store,
            service: repository.myStocks,
            market: market.config,
          ),
        ),
      ],
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

  /// Symbols in this market whose curve can actually be fetched here, mapped to
  /// the target that fetches it. Resolved once per build so the tables can mark
  /// only the rows that open something. Platform-aware: on Web with no proxy,
  /// Yahoo is unreachable and those rows correctly go inert.
  ///
  /// [saved] is resolved first: a user-added stock carries the queryable id its
  /// search returned, so it resolves where [HistoryTarget.forSymbol] — which
  /// only knows `markets.dart` — would rightly give up.
  Map<String, HistoryTarget> _chartTargets(
    BuildContext context,
    Market m,
    List<SavedStock> saved,
  ) {
    final service = context.read<DashboardRepository>().history;
    final out = <String, HistoryTarget>{};

    for (final stock in saved) {
      final target = HistoryTarget.fromSaved(m.config, stock);
      if (service.canServe(target)) out[stock.symbol] = target;
    }

    final symbols = {
      ...m.leaders.map((l) => l.symbol),
      ...m.movers.map((v) => v.symbol),
    };
    for (final symbol in symbols) {
      if (out.containsKey(symbol)) continue;
      final target = HistoryTarget.forSymbol(m.config, symbol);
      if (target != null && service.canServe(target)) out[symbol] = target;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyStocksCubit, MyStocksState>(
      builder: (context, mine) => _content(context, mine),
    );
  }

  Widget _content(BuildContext context, MyStocksState mine) {
    final m = state.market;
    final targets = _chartTargets(context, m, mine.saved);
    final chartable = targets.keys.toSet();
    void openChart(String symbol) {
      final target = targets[symbol];
      if (target != null) showInstrumentChart(context, target);
    }

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
          LeadersTable(
            leaders: m.leaders,
            chartable: chartable,
            onSymbolTap: openChart,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _MyStocksSection(
          market: m,
          mine: mine,
          chartable: chartable,
          onSymbolTap: openChart,
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionLabel('Top movers · session'),
        const SizedBox(height: AppSpacing.xs + 2),
        if (state.hasMovers)
          MoversTable(
            movers: m.movers,
            chartable: chartable,
            onSymbolTap: openChart,
          )
        else
          const EmptyState(
            icon: TablerIcons.chart_bar_off,
            title: 'No movers for this session',
            hint: 'They appear once the market has traded.',
          ),
        if (targets.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap a highlighted ticker for its price curve.',
            style: AppText.caption,
          ),
        ],
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

/// The user's own stocks for this market — the one section here that isn't
/// curated. Sits between the curated leaders and the session's movers so the
/// two lists above and below keep meaning exactly what they say.
class _MyStocksSection extends StatelessWidget {
  final Market market;
  final MyStocksState mine;
  final Set<String> chartable;
  final void Function(String symbol) onSymbolTap;

  const _MyStocksSection({
    required this.market,
    required this.mine,
    required this.chartable,
    required this.onSymbolTap,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MyStocksCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel('My stocks · ${market.currency}')),
            if (mine.canSearch)
              AppPill(
                label: 'Add stock',
                icon: TablerIcons.plus,
                active: false,
                onTap: () => showAddStock(context, cubit),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        const SignInBanner(),
        if (mine.isEmpty)
          EmptyState(
            icon: TablerIcons.list_search,
            title: mine.canSearch
                ? 'No stocks added yet'
                : 'Search isn\'t available here',
            hint: mine.canSearch
                ? 'Use "Add stock" to follow any ${market.name} listing.'
                : 'This platform can\'t reach ${market.name}\'s search source.',
          )
        else
          MyStocksTable(
            state: mine,
            chartable: chartable,
            onSymbolTap: onSymbolTap,
            onRemove: cubit.remove,
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
