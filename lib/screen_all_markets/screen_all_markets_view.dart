import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:material_table_view/material_table_view.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../shared/widgets/app_table.dart';
import '../shared/widgets/common.dart';
import '../shared/widgets/controls.dart';
import '../shared/widgets/surfaces.dart';
import 'cubit/screen_all_markets_cubit.dart';

/// "Screen — all markets": every market's movers + leaders flattened into one
/// sortable, filterable table, so instruments can be ranked across all 7 markets
/// at once.
///
/// All of the sort/filter logic lives in [ScreenAllMarketsCubit]; this widget
/// only renders the state and reports taps. A row tap hands the row's market id
/// back to [onMarketTap] — the same details dialog a tile opens.
class ScreenAllMarketsView extends StatelessWidget {
  final ValueChanged<String> onMarketTap;

  const ScreenAllMarketsView({super.key, required this.onMarketTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenAllMarketsCubit, ScreenAllMarketsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: SectionLabel('Screen — all markets')),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  state.rows.length == state.totalCount
                      ? '${state.totalCount} instruments'
                      : '${state.rows.length} of ${state.totalCount}',
                  style: AppText.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Controls(state: state),
            const SizedBox(height: AppSpacing.md),
            if (state.rows.isEmpty)
              EmptyState(
                icon: state.totalCount == 0
                    ? TablerIcons.chart_bar_off
                    : TablerIcons.filter_off,
                title: state.totalCount == 0
                    ? 'No instruments loaded yet'
                    : 'No instruments match these filters',
                hint: state.totalCount == 0
                    ? 'Refresh to fetch movers and leading stocks.'
                    : 'Clear the filters to see all '
                          '${state.totalCount} instruments.',
              )
            else
              _Table(state: state, onMarketTap: onMarketTap),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              'Ranks the live movers & leaders already fetched per market. '
              'Tap a column to sort, or a row to open its market. '
              'Not investment advice.',
              style: AppText.caption,
            ),
          ],
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  final ScreenAllMarketsState state;
  const _Controls({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScreenAllMarketsCubit>();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Gain/loss filter.
        for (final f in ChangeFilter.values)
          AppPill(
            label: f.label,
            active: state.changeFilter == f,
            activeColor: switch (f) {
              ChangeFilter.gainers => AppColors.gain,
              ChangeFilter.losers => AppColors.loss,
              ChangeFilter.all => AppColors.accent,
            },
            onTap: () => cubit.setChangeFilter(f),
          ),
        const PillDivider(),
        // Market filter — the flag alone, with the market name as its tooltip.
        AppPill(
          label: 'All markets',
          active: state.marketId == null,
          onTap: () => cubit.setMarketFilter(null),
        ),
        for (final m in state.markets)
          AppPill(
            label: m.flag,
            tooltip: m.name,
            active: state.marketId == m.id,
            onTap: () => cubit.setMarketFilter(m.id),
          ),
        const PillDivider(),
        AppSearchField(hint: 'Search ticker / name', onChanged: cubit.search),
        if (state.isFiltered)
          AppPill(
            label: 'Clear',
            icon: TablerIcons.filter_off,
            active: false,
            onTap: cubit.clearFilters,
          ),
      ],
    );
  }
}

class _Table extends StatelessWidget {
  final ScreenAllMarketsState state;
  final ValueChanged<String> onMarketTap;

  const _Table({required this.state, required this.onMarketTap});

  static const _columns = [
    TableColumn(width: 44),
    TableColumn(width: 78),
    TableColumn(width: 120, flex: 1),
    TableColumn(width: 82),
    TableColumn(width: 64),
    TableColumn(width: 66),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScreenAllMarketsCubit>();
    return AppTable(
      rowCount: state.rows.length,
      columns: _columns,
      onRowTap: (row) => onMarketTap(state.rows[row].marketId),
      headerCell: (col) => _HeaderCell(
        sort: ScreenerSort.values[col],
        active: ScreenerSort.values[col] == state.sort,
        ascending: state.ascending,
        onTap: () => cubit.sortBy(ScreenerSort.values[col]),
      ),
      cell: (row, col) => _cell(state.rows[row], col),
    );
  }

  Widget _cell(ScreenerRow r, int col) => switch (col) {
    0 => Text(r.flag, style: const TextStyle(fontSize: 14)),
    1 => Text(r.symbol, style: AppText.numCell),
    2 => Text(r.name, overflow: TextOverflow.ellipsis, style: AppText.bodyMuted),
    3 => Text(
      r.price == null ? '—' : Fmt.price(r.price!),
      style: r.price == null
          ? AppText.numCell.copyWith(color: AppColors.ink3)
          : AppText.numCell,
    ),
    4 => ChangeText(r.changePct),
    _ => Text(
      r.divYield == null ? '—' : '${r.divYield!.toStringAsFixed(2)}%',
      style: AppText.numCell.copyWith(
        color: r.divYield == null ? AppColors.ink3 : AppColors.accent,
      ),
    ),
  };
}

/// A tappable, sort-indicating column header.
class _HeaderCell extends StatelessWidget {
  final ScreenerSort sort;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;

  const _HeaderCell({
    required this.sort,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: TableHeaderText(sort.header)),
            if (active) ...[
              const SizedBox(width: 2),
              Icon(
                ascending ? TablerIcons.chevron_up : TablerIcons.chevron_down,
                size: 11,
                color: AppColors.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
