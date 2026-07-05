import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import 'common.dart';
import 'data_table.dart';

/// Leading (heavyweight) stocks: Ticker · Company · Price · Chg · Div yield.
/// Only shown for markets that curate a `leaders` list.
class LeadersTable extends StatelessWidget {
  final List<Leader> leaders;
  const LeadersTable({super.key, required this.leaders});

  static const _headers = ['Ticker', 'Company', 'Price', 'Chg', 'Div yield'];

  @override
  Widget build(BuildContext context) {
    if (leaders.isEmpty) return const SizedBox.shrink();
    return AppTable(
      rowCount: leaders.length,
      columns: const [
        TableColumn(width: 80),
        TableColumn(width: 130, flex: 1),
        TableColumn(width: 74),
        TableColumn(width: 60),
        TableColumn(width: 78),
      ],
      headerCell: (c) => TableHeaderText(_headers[c]),
      cell: (row, col) {
        final s = leaders[row];
        return switch (col) {
          0 => Text(
            s.symbol,
            style: AppText.mono.copyWith(fontSize: 12.5, color: AppColors.ink),
          ),
          1 => Text(
            s.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
          ),
          2 => Text(
            Fmt.price(s.price),
            style: AppText.mono.copyWith(fontSize: 12.5, color: AppColors.ink),
          ),
          3 => ChangeText(s.changePct),
          _ => _DividendCell(s.dividend),
        };
      },
    );
  }
}

/// Gold yield %, or a muted "—" for a genuine non-payer.
class _DividendCell extends StatelessWidget {
  final Dividend? dividend;
  const _DividendCell(this.dividend);

  @override
  Widget build(BuildContext context) {
    final d = dividend;
    if (d == null) {
      return Text(
        '—',
        style: AppText.mono.copyWith(fontSize: 12.5, color: AppColors.ink3),
      );
    }
    final tip = [
      '${d.yield.toStringAsFixed(2)}% yield',
      if (d.frequency != null) d.frequency!,
      'annual ${Fmt.price(d.annual)}',
      if (d.exDate != null) 'ex-div ${d.exDate}',
    ].join(' · ');
    return Tooltip(
      message: tip,
      child: Text(
        '${d.yield.toStringAsFixed(2)}%',
        style: AppText.mono.copyWith(fontSize: 12.5, color: AppColors.accent),
      ),
    );
  }
}
