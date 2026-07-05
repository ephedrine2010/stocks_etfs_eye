import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';

import '../../app/theme.dart';
import '../../data/models/models.dart';
import 'common.dart';
import 'data_table.dart';

/// Cross-market watchlist normalized to USD: Symbol · Native · USD · Chg.
class WatchlistTable extends StatelessWidget {
  final List<WatchRow> rows;
  const WatchlistTable({super.key, required this.rows});

  static const _headers = ['Symbol', 'Native', 'USD', 'Chg'];

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return AppTable(
      rowCount: rows.length,
      rowHeight: 46,
      columns: const [
        TableColumn(width: 150, flex: 1),
        TableColumn(width: 90),
        TableColumn(width: 84),
        TableColumn(width: 56),
      ],
      headerCell: (c) => TableHeaderText(_headers[c]),
      cell: (row, col) {
        final r = rows[row];
        return switch (col) {
          0 => _SymbolCell(r),
          1 => Text(
            r.native,
            overflow: TextOverflow.ellipsis,
            style: AppText.mono.copyWith(fontSize: 12.5, color: AppColors.ink),
          ),
          2 => Text(
            r.usd,
            overflow: TextOverflow.ellipsis,
            style: AppText.mono.copyWith(fontSize: 12.5, color: AppColors.ink2),
          ),
          _ => ChangeText(r.changePct),
        };
      },
    );
  }
}

class _SymbolCell extends StatelessWidget {
  final WatchRow row;
  const _SymbolCell(this.row);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(row.flag, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.symbol,
                overflow: TextOverflow.ellipsis,
                style: AppText.mono.copyWith(
                  fontSize: 12.5,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                row.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
