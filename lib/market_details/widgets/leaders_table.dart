import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/app_table.dart';
import '../../shared/widgets/common.dart';

/// Leading (heavyweight) stocks: Ticker · Company · Price · Chg · Div yield.
/// Only shown for markets that curate a `leaders` list.
/// Tapping a row opens that stock's price curve — but only for the symbols the
/// parent lists in [chartable]. A row we can't chart stays inert and unmarked
/// rather than opening a view that can only say "N.A.".
class LeadersTable extends StatelessWidget {
  final List<Leader> leaders;
  final Set<String> chartable;
  final void Function(String symbol)? onSymbolTap;

  const LeadersTable({
    super.key,
    required this.leaders,
    this.chartable = const {},
    this.onSymbolTap,
  });

  static const _headers = ['Ticker', 'Company', 'Price', 'Chg', 'Div yield'];

  bool _opens(int row) =>
      onSymbolTap != null && chartable.contains(leaders[row].symbol);

  @override
  Widget build(BuildContext context) {
    if (leaders.isEmpty) return const SizedBox.shrink();
    return AppTable(
      rowCount: leaders.length,
      onRowTap: onSymbolTap == null
          ? null
          : (row) {
              if (_opens(row)) onSymbolTap!(leaders[row].symbol);
            },
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
            style: _opens(row)
                ? AppText.numCell.copyWith(color: AppColors.accent)
                : AppText.numCell,
          ),
          1 => Text(
            s.name,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyMuted,
          ),
          2 => Text(Fmt.price(s.price), style: AppText.numCell),
          3 => ChangeText(s.changePct),
          _ => DividendCell(s.dividend),
        };
      },
    );
  }
}

/// Gold yield %, or a muted "—" for a genuine non-payer — never a fake 0%.
/// Shared with the "My stocks" table so an added row reads identically.
class DividendCell extends StatelessWidget {
  final Dividend? dividend;
  const DividendCell(this.dividend, {super.key});

  @override
  Widget build(BuildContext context) {
    final d = dividend;
    if (d == null) {
      return Text('—', style: AppText.numCell.copyWith(color: AppColors.ink3));
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
        style: AppText.numCell.copyWith(color: AppColors.accent),
      ),
    );
  }
}
