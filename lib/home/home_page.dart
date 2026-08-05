import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../app/theme.dart';
import '../data/models/models.dart';
import '../market_details/market_details_dialog.dart';
import '../markets_list/cubit/markets_list_cubit.dart';
import '../markets_list/markets_list_view.dart';
import '../screen_all_markets/cubit/screen_all_markets_cubit.dart';
import '../screen_all_markets/screen_all_markets_view.dart';
import '../shared/widgets/surfaces.dart';
import 'cubit/home_cubit.dart';
import 'widgets/home_topbar.dart';

/// The main page: the cross-market screener on top, the live market tiles below.
///
/// [HomeCubit] is the only thing that talks to the repository. This page owns
/// the two section cubits and hands each the freshly-loaded markets — the
/// sections never fetch anything themselves.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Seeded from whatever the home cubit already holds, so a hot reload (or
        // a load that resolved before this page built) doesn't start empty.
        BlocProvider(
          create: (ctx) => ScreenAllMarketsCubit(
            markets: ctx.read<HomeCubit>().state.markets,
          ),
        ),
        BlocProvider(
          create: (ctx) =>
              MarketsListCubit(markets: ctx.read<HomeCubit>().state.markets),
        ),
      ],
      child: BlocListener<HomeCubit, HomeState>(
        listenWhen: (_, next) => next is HomeLoaded,
        listener: (context, state) {
          context.read<ScreenAllMarketsCubit>().setMarkets(state.markets);
          context.read<MarketsListCubit>().setMarkets(state.markets);
        },
        child: Scaffold(
          body: SafeArea(
            child: BlocBuilder<HomeCubit, HomeState>(
              // `_Content` is const, so a refresh doesn't rebuild the page —
              // each section rebuilds from its own cubit instead.
              builder: (context, state) => switch (state) {
                HomeLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                HomeError(:final message) => _ErrorView(message: message),
                HomeLoaded() => const _Content(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl - 2,
            AppSpacing.xxl - 2,
            AppSpacing.xxl - 2,
            60,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeTopbar(),
              const SizedBox(height: AppSpacing.xxl),
              AppCard(
                child: ScreenAllMarketsView(
                  onMarketTap: (id) => _openById(context, id),
                ),
              ),
              const SizedBox(height: AppSpacing.huge - 4),
              MarketsListView(
                onMarketTap: (market) => showMarketDetails(context, market),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }

  /// A screener row knows its market by id; resolve it against the loaded data.
  void _openById(BuildContext context, String marketId) {
    final state = context.read<HomeCubit>().state;
    final market = state.markets.cast<Market?>().firstWhere(
      (m) => m?.id == marketId,
      orElse: () => null,
    );
    if (market != null) showMarketDetails(context, market);
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Text(
    'Trading hours & weekends are per-market: KSA & Egypt trade Sun–Thu; USA, '
    'China & UAE trade Mon–Fri, China with a midday break. Gold ~24h Mon–Fri; '
    'Crypto is 24/7/365. Open/closed is computed live from your device clock. '
    'Informational only — not investment advice.',
    style: AppText.caption,
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            TablerIcons.plug_connected_x,
            size: AppIconSize.empty,
            color: AppColors.ink3,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Failed to load the dashboard', style: AppText.title),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppText.caption, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.read<HomeCubit>().load(),
            icon: const Icon(TablerIcons.refresh, size: AppIconSize.dense),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
