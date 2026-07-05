import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/theme.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/selection_cubit.dart';
import '../data/models/models.dart';
import 'widgets/brief_card.dart';
import 'widgets/common.dart';
import 'widgets/detail_panel.dart';
import 'widgets/market_grid.dart';
import 'widgets/screener_table.dart';
import 'widgets/topbar.dart';
import 'widgets/watchlist_table.dart';

/// The full dashboard: topbar · brief · tiles · (detail | watchlist) · footer.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) => switch (state) {
            DashboardLoading() => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            DashboardError(:final message) => _ErrorView(message: message),
            DashboardLoaded(:final dashboard) => _Content(dashboard: dashboard),
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final Dashboard dashboard;
  const _Content({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    // Default the selection to the first market once data is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dashboard.markets.isNotEmpty) {
        context.read<SelectionCubit>().ensureSelection(dashboard.markets.first.id);
      }
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Topbar(markets: dashboard.markets),
              const SizedBox(height: 22),
              if (dashboard.brief != null)
                BriefCard(brief: dashboard.brief!, asOf: dashboard.asOf),
              const SizedBox(height: 28),
              const SectionLabel('Markets — live status'),
              const SizedBox(height: 12),
              BlocBuilder<SelectionCubit, String?>(
                builder: (context, selectedId) => MarketGrid(
                  markets: dashboard.markets,
                  selectedId: selectedId,
                  onSelect: (id) => context.read<SelectionCubit>().select(id),
                ),
              ),
              const SizedBox(height: 28),
              _Card(child: ScreenerTable(markets: dashboard.markets)),
              const SizedBox(height: 28),
              _DetailAndWatchlist(dashboard: dashboard),
              const SizedBox(height: 24),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Side-by-side (detail | watchlist) on wide screens; stacked on narrow.
class _DetailAndWatchlist extends StatelessWidget {
  final Dashboard dashboard;
  const _DetailAndWatchlist({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final detail = BlocBuilder<SelectionCubit, String?>(
      builder: (context, selectedId) {
        final market = selectedId == null
            ? dashboard.markets.first
            : (dashboard.marketById(selectedId) ?? dashboard.markets.first);
        return _Card(child: DetailPanel(market: market));
      },
    );

    final watchlist = _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Watchlist · normalized to USD'),
          const SizedBox(height: 14),
          WatchlistTable(rows: dashboard.watchlist),
          const SizedBox(height: 12),
          const Text(
            'Native currency shown with USD conversion beside it. FX rates are '
            'approximate (static) until a live FX source is wired.',
            style: TextStyle(fontSize: 11, color: AppColors.ink3),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 820) {
          return Column(
            children: [detail, const SizedBox(height: 16), watchlist],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: detail),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: watchlist),
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: child,
  );
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => const Text(
    'Trading hours & weekends are per-market: KSA & Egypt trade Sun–Thu; USA, '
    'China & UAE trade Mon–Fri, China with a midday break. Gold ~24h Mon–Fri; '
    'Crypto is 24/7/365. Open/closed is computed live from your device clock.',
    style: TextStyle(fontSize: 11, color: AppColors.ink3, height: 1.5),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Failed to load dashboard',
            style: TextStyle(color: AppColors.ink, fontSize: 16)),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: AppColors.ink3)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.read<DashboardCubit>().load(),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}
