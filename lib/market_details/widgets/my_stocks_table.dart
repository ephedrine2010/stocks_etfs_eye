import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:material_table_view/material_table_view.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/app_table.dart';
import '../../shared/widgets/common.dart';
import '../cubit/my_stocks_cubit.dart';
import 'leaders_table.dart' show DividendCell;

/// The user's own stocks for this market: Ticker · Company · Price · Chg ·
/// Div yield, plus a remove action. Deliberately the same five columns as
/// [LeadersTable] — an added stock is not a lesser row, it just wasn't curated.
///
/// A saved stock the source couldn't price still renders, with muted "—"s. It
/// was explicitly added by the user; dropping it would read as the app having
/// forgotten it, which is worse than admitting a missing price.
class MyStocksTable extends StatelessWidget {
  final MyStocksState state;
  final Set<String> chartable;
  final void Function(String symbol)? onSymbolTap;
  final void Function(SavedStock stock) onRemove;

  const MyStocksTable({
    super.key,
    required this.state,
    required this.onRemove,
    this.chartable = const {},
    this.onSymbolTap,
  });

  static const _headers = ['Ticker', 'Company', 'Price', 'Chg', 'Div yield', ''];

  bool _opens(int row) =>
      onSymbolTap != null && chartable.contains(state.saved[row].symbol);

  @override
  Widget build(BuildContext context) {
    final saved = state.saved;
    if (saved.isEmpty) return const SizedBox.shrink();

    return AppTable(
      rowCount: saved.length,
      onRowTap: onSymbolTap == null
          ? null
          : (row) {
              if (_opens(row)) onSymbolTap!(saved[row].symbol);
            },
      columns: const [
        TableColumn(width: 80),
        TableColumn(width: 120, flex: 1),
        TableColumn(width: 74),
        TableColumn(width: 60),
        TableColumn(width: 78),
        TableColumn(width: 40),
      ],
      headerCell: (c) => TableHeaderText(_headers[c]),
      cell: (row, col) {
        final stock = saved[row];
        final live = state.rowFor(stock);
        return switch (col) {
          0 => Text(
            stock.symbol,
            style: _opens(row)
                ? AppText.numCell.copyWith(color: AppColors.accent)
                : AppText.numCell,
          ),
          1 => Text(
            stock.name,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyMuted,
          ),
          2 => live == null
              ? const _Pending()
              : Text(Fmt.price(live.price), style: AppText.numCell),
          3 => live == null ? const _Pending() : ChangeText(live.changePct),
          4 => live == null ? const _Pending() : DividendCell(live.dividend),
          _ => _RemoveButton(onPressed: () => onRemove(stock)),
        };
      },
    );
  }
}

/// A value that isn't in yet, or that this source couldn't provide.
class _Pending extends StatelessWidget {
  const _Pending();

  @override
  Widget build(BuildContext context) =>
      Text('—', style: AppText.numCell.copyWith(color: AppColors.ink3));
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _RemoveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Remove from my stocks',
      onPressed: onPressed,
      icon: const Icon(TablerIcons.trash, size: AppIconSize.inline),
      color: AppColors.ink3,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.huge,
        minHeight: AppSpacing.huge,
      ),
    );
  }
}
