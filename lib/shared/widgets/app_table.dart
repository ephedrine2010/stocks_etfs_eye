import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';

import '../../app/theme.dart';

/// Thin wrapper around [TableView.builder] for our read-only, shrink-wrapped
/// tables (screener / movers / leaders). The table shrink-wraps vertically so
/// it composes inside the page's scroll view, and never scrolls vertically
/// itself; it still scrolls horizontally on narrow screens (the "overflow-x"
/// behaviour from the old CSS).
///
/// Row separation is a rule in [AppColors.line] — never a zebra fill.
class AppTable extends StatelessWidget {
  final List<TableColumn> columns;

  /// Header cell for a given column index.
  final Widget Function(int column) headerCell;

  /// Body cell for (row, column).
  final Widget Function(int row, int column) cell;

  /// Optional row tap — used where a row opens something.
  final void Function(int row)? onRowTap;

  final int rowCount;
  final double rowHeight;
  final double headerHeight;

  const AppTable({
    super.key,
    required this.columns,
    required this.headerCell,
    required this.cell,
    required this.rowCount,
    this.onRowTap,
    this.rowHeight = 42,
    this.headerHeight = 34,
  });

  @override
  Widget build(BuildContext context) {
    return TableView.builder(
      columns: columns,
      rowCount: rowCount,
      rowHeight: rowHeight,
      headerHeight: headerHeight,
      shrinkWrapVertical: true,
      physics: const NeverScrollableScrollPhysics(),
      style: const TableViewStyle(
        dividers: TableViewDividersStyle(
          horizontal: TableViewHorizontalDividersStyle.symmetric(
            TableViewHorizontalDividerStyle(color: AppColors.line, thickness: 1),
          ),
          vertical: TableViewVerticalDividersStyle.symmetric(
            TableViewVerticalDividerStyle(thickness: 0),
          ),
        ),
      ),
      headerBuilder: (context, contentBuilder) => contentBuilder(
        context,
        (context, column) =>
            Align(alignment: _align(column), child: headerCell(column)),
      ),
      rowBuilder: (context, row, contentBuilder) {
        final content = contentBuilder(
          context,
          (context, column) => Align(
            alignment: _align(column),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: cell(row, column),
            ),
          ),
        );
        return Material(
          type: MaterialType.transparency,
          child: onRowTap == null
              ? content
              : InkWell(onTap: () => onRowTap!(row), child: content),
        );
      },
    );
  }

  // First column left-aligned, the rest right-aligned (numeric columns).
  Alignment _align(int column) =>
      column == 0 ? Alignment.centerLeft : Alignment.centerRight;
}

/// Right/left aligned header label.
class TableHeaderText extends StatelessWidget {
  final String text;
  const TableHeaderText(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text, style: AppText.columnHeader);
}
