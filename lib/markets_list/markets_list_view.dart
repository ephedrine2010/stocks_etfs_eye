import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../app/theme.dart';
import '../data/models/models.dart';
import '../shared/widgets/common.dart';
import '../shared/widgets/controls.dart';
import '../shared/widgets/surfaces.dart';
import 'cubit/markets_list_cubit.dart';
import 'widgets/market_tile.dart';

/// "Markets — live status": every tracked market as a tile, filterable by
/// open/closed, ticking once a second off [MarketsListCubit].
///
/// The section owns no data of its own — it renders whatever the cubit holds and
/// hands a tap back to [onMarketTap], so the caller decides what opening a
/// market means (today: the details dialog).
class MarketsListView extends StatelessWidget {
  final ValueChanged<Market> onMarketTap;

  const MarketsListView({super.key, required this.onMarketTap});

  static const _gap = AppSpacing.md;
  static const _minTile = 172.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketsListCubit, MarketsListState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(state: state),
            const SizedBox(height: AppSpacing.md),
            if (state.statuses.isEmpty)
              const EmptyState(
                icon: TablerIcons.building_off,
                title: 'No markets loaded',
                hint: 'Refresh to fetch the market list again.',
              )
            else if (state.visible.isEmpty)
              EmptyState(
                icon: TablerIcons.clock_off,
                title:
                    'No ${state.filter.label.toLowerCase()} markets right now',
                hint: 'Switch to "All" to see every market.',
              )
            else
              _Grid(statuses: state.visible, onMarketTap: onMarketTap),
          ],
        );
      },
    );
  }
}

/// Section label + the open count + the open/closed filter.
class _Header extends StatelessWidget {
  final MarketsListState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MarketsListCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Markets — live status')),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${state.openCount} of ${state.total} open',
              style: AppText.caption,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final f in MarketFilter.values)
              AppPill(
                label: '${f.label} · ${state.countFor(f)}',
                active: state.filter == f,
                activeColor: switch (f) {
                  MarketFilter.open => AppColors.gain,
                  MarketFilter.closed => AppColors.ink2,
                  MarketFilter.all => AppColors.accent,
                },
                onTap: () => cubit.setFilter(f),
              ),
          ],
        ),
      ],
    );
  }
}

/// Responsive grid of tiles — `repeat(auto-fit, minmax(172px, 1fr))` from the
/// old CSS, reproduced with a LayoutBuilder + Wrap.
class _Grid extends StatelessWidget {
  final List<MarketStatus> statuses;
  final ValueChanged<Market> onMarketTap;

  const _Grid({required this.statuses, required this.onMarketTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = MarketsListView._gap;
        final w = c.maxWidth;
        var cols = ((w + gap) / (MarketsListView._minTile + gap)).floor();
        cols = cols.clamp(1, statuses.length);
        final tileW = (w - (cols - 1) * gap) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in statuses)
              SizedBox(
                width: tileW,
                child: MarketTile(
                  key: ValueKey(s.id),
                  status: s,
                  onTap: () => onMarketTap(s.market),
                ),
              ),
          ],
        );
      },
    );
  }
}
