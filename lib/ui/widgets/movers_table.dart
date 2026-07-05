import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';

import '../../app/theme.dart';
import '../../data/models/models.dart';
import 'common.dart';
import 'data_table.dart';

/// Top movers table: Ticker · Company · Chg.
class MoversTable extends StatelessWidget {
  final List<Mover> movers;
  const MoversTable({super.key, required this.movers});

  static const _headers = ['Ticker', 'Company', 'Chg'];

  @override
  Widget build(BuildContext context) {
    if (movers.isEmpty) return const SizedBox.shrink();
    return AppTable(
      rowCount: movers.length,
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
            style: AppText.mono.copyWith(fontSize: 12.5, color: AppColors.ink),
          ),
          1 => Text(
            m.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
          ),
          _ => ChangeText(m.changePct),
        };
      },
    );
  }
}
