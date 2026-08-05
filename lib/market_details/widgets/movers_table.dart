import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';

import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/app_table.dart';
import '../../shared/widgets/common.dart';

/// Top movers table: Ticker · Company · Chg.
///
/// Tapping a row opens that stock's price curve — but only for the symbols the
/// parent lists in [chartable]. A row we can't chart stays inert and unmarked
/// rather than opening a view that can only say "N.A.".
class MoversTable extends StatelessWidget {
  final List<Mover> movers;
  final Set<String> chartable;
  final void Function(String symbol)? onSymbolTap;

  const MoversTable({
    super.key,
    required this.movers,
    this.chartable = const {},
    this.onSymbolTap,
  });

  static const _headers = ['Ticker', 'Company', 'Chg'];

  bool _opens(int row) =>
      onSymbolTap != null && chartable.contains(movers[row].symbol);

  @override
  Widget build(BuildContext context) {
    if (movers.isEmpty) return const SizedBox.shrink();
    return AppTable(
      rowCount: movers.length,
      onRowTap: onSymbolTap == null
          ? null
          : (row) {
              if (_opens(row)) onSymbolTap!(movers[row].symbol);
            },
      columns: const [
        TableColumn(width: 80),
        TableColumn(width: 120, flex: 1),
        TableColumn(width: 64),
      ],
      headerCell: (c) => TableHeaderText(_headers[c]),
      cell: (row, col) {
        final m = movers[row];
        return switch (col) {
          0 => Text(
            m.symbol,
            style: _opens(row)
                ? AppText.numCell.copyWith(color: AppColors.accent)
                : AppText.numCell,
          ),
          1 => Text(
            m.name,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyMuted,
          ),
          _ => ChangeText(m.changePct),
        };
      },
    );
  }
}
