import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:material_table_view/material_table_view.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import 'common.dart';
import 'data_table.dart';

/// Cross-market screener: flattens every market's movers + leaders into one
/// sortable, filterable table so you can rank instruments across all 7 markets
/// at once. Reuses the live data already fetched — no extra API calls.
///
/// View-only sort/filter state is ephemeral, so it lives here in local widget
/// state (Flutter's built-in [State]) rather than a shared cubit, which is
/// reserved for domain/data state (see [SelectionCubit]).
class ScreenerTable extends StatefulWidget {
  final List<Market> markets;
  const ScreenerTable({super.key, required this.markets});

  @override
  State<ScreenerTable> createState() => _ScreenerTableState();
}

/// What to sort the screener by. Maps 1:1 to the tappable column headers.
enum _SortKey { market, ticker, name, price, change, div }

/// Gain/loss quick filter.
enum _Filter { all, gainers, losers }

/// One flattened instrument row.
class _Row {
  final int order; // market display order, for the "Market" sort
  final String flag;
  final String marketId;
  final String symbol;
  final String name;
  final double? price;
  final double changePct;
  final double? divYield;

  const _Row({
    required this.order,
    required this.flag,
    required this.marketId,
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePct,
    required this.divYield,
  });
}

class _ScreenerTableState extends State<ScreenerTable> {
  _SortKey _sortKey = _SortKey.change;
  bool _asc = false; // default: biggest movers first
  _Filter _filter = _Filter.all;
  String _query = '';
  String? _marketId; // null ⇒ all markets

  static const _headers = ['Mkt', 'Ticker', 'Company', 'Price', 'Chg', 'Div'];
  static const _sortForCol = [
    _SortKey.market,
    _SortKey.ticker,
    _SortKey.name,
    _SortKey.price,
    _SortKey.change,
    _SortKey.div,
  ];

  /// Flatten markets → rows, de-duped by market+symbol. Leaders win over movers
  /// on collision (they carry price + dividend); movers fill the rest.
  List<_Row> _allRows() {
    final map = <String, _Row>{};
    for (var i = 0; i < widget.markets.length; i++) {
      final m = widget.markets[i];
      for (final l in m.leaders) {
        map['${m.id}:${l.symbol}'] = _Row(
          order: i,
          flag: m.flag,
          marketId: m.id,
          symbol: l.symbol,
          name: l.name,
          price: l.price,
          changePct: l.changePct,
          divYield: l.dividend?.yield,
        );
      }
      for (final mv in m.movers) {
        map.putIfAbsent(
          '${m.id}:${mv.symbol}',
          () => _Row(
            order: i,
            flag: m.flag,
            marketId: m.id,
            symbol: mv.symbol,
            name: mv.name,
            price: mv.price,
            changePct: mv.changePct,
            divYield: null,
          ),
        );
      }
    }
    return map.values.toList();
  }

  List<_Row> _visibleRows() {
    final q = _query.trim().toLowerCase();
    final rows = _allRows().where((r) {
      if (_marketId != null && r.marketId != _marketId) return false;
      if (_filter == _Filter.gainers && r.changePct < 0) return false;
      if (_filter == _Filter.losers && r.changePct >= 0) return false;
      if (q.isNotEmpty &&
          !r.symbol.toLowerCase().contains(q) &&
          !r.name.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
    rows.sort(_compare);
    return rows;
  }

  int _compare(_Row a, _Row b) {
    switch (_sortKey) {
      case _SortKey.market:
        return _dir(a.order.compareTo(b.order));
      case _SortKey.ticker:
        return _dir(a.symbol.compareTo(b.symbol));
      case _SortKey.name:
        return _dir(a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _SortKey.change:
        return _dir(a.changePct.compareTo(b.changePct));
      case _SortKey.price:
        return _nullableCmp(a.price, b.price);
      case _SortKey.div:
        return _nullableCmp(a.divYield, b.divYield);
    }
  }

  int _dir(int c) => _asc ? c : -c;

  /// Nulls always sort last, independent of direction.
  int _nullableCmp(num? x, num? y) {
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return _dir(x.compareTo(y));
  }

  void _sortBy(_SortKey key) => setState(() {
        if (_sortKey == key) {
          _asc = !_asc;
        } else {
          _sortKey = key;
          // Text columns default A→Z; numeric columns default high→low.
          _asc = key == _SortKey.ticker ||
              key == _SortKey.name ||
              key == _SortKey.market;
        }
      });

  @override
  Widget build(BuildContext context) {
    final rows = _visibleRows();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Screener · all markets')),
            const SizedBox(width: 8),
            Text(
              '${rows.length} instruments',
              style: const TextStyle(fontSize: 11, color: AppColors.ink3),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _controls(),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'No instruments match these filters.',
              style: TextStyle(fontSize: 12.5, color: AppColors.ink3),
            ),
          )
        else
          _table(rows),
        const SizedBox(height: 10),
        const Text(
          'Ranks the live movers & leaders already fetched per market. '
          'Tap a column to sort. Not investment advice.',
          style: TextStyle(fontSize: 11, color: AppColors.ink3, height: 1.5),
        ),
      ],
    );
  }

  Widget _controls() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Gain/loss filter.
        _Pill(
          label: 'All',
          active: _filter == _Filter.all,
          onTap: () => setState(() => _filter = _Filter.all),
        ),
        _Pill(
          label: 'Gainers',
          active: _filter == _Filter.gainers,
          activeColor: AppColors.gain,
          onTap: () => setState(() => _filter = _Filter.gainers),
        ),
        _Pill(
          label: 'Losers',
          active: _filter == _Filter.losers,
          activeColor: AppColors.loss,
          onTap: () => setState(() => _filter = _Filter.losers),
        ),
        const _Sep(),
        // Market filter.
        _Pill(
          label: '🌐 All',
          active: _marketId == null,
          onTap: () => setState(() => _marketId = null),
        ),
        for (final m in widget.markets)
          _Pill(
            label: m.flag,
            active: _marketId == m.id,
            onTap: () => setState(() => _marketId = m.id),
          ),
        const _Sep(),
        // Search.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: SizedBox(
            height: 32,
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search ticker / name',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.ink3),
                prefixIcon: const Icon(TablerIcons.search,
                    size: 15, color: AppColors.ink3),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 30, minHeight: 30),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: AppColors.surface2,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accentDim),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _table(List<_Row> rows) {
    return AppTable(
      rowCount: rows.length,
      columns: const [
        TableColumn(width: 44),
        TableColumn(width: 78),
        TableColumn(width: 120, flex: 1),
        TableColumn(width: 82),
        TableColumn(width: 64),
        TableColumn(width: 66),
      ],
      headerCell: _headerCell,
      cell: (row, col) => _bodyCell(rows[row], col),
    );
  }

  Widget _headerCell(int col) {
    final key = _sortForCol[col];
    final active = key == _sortKey;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _sortBy(key),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TableHeaderText(_headers[col]),
            ),
            if (active) ...[
              const SizedBox(width: 2),
              Icon(
                _asc ? TablerIcons.chevron_up : TablerIcons.chevron_down,
                size: 11,
                color: AppColors.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bodyCell(_Row r, int col) {
    return switch (col) {
      0 => Text(r.flag, style: const TextStyle(fontSize: 14)),
      1 => Text(
          r.symbol,
          style: AppText.mono.copyWith(fontSize: 12.5, color: AppColors.ink),
        ),
      2 => Text(
          r.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
        ),
      3 => Text(
          r.price == null ? '—' : Fmt.price(r.price!),
          style: AppText.mono.copyWith(
            fontSize: 12.5,
            color: r.price == null ? AppColors.ink3 : AppColors.ink,
          ),
        ),
      4 => ChangeText(r.changePct),
      _ => Text(
          r.divYield == null ? '—' : '${r.divYield!.toStringAsFixed(2)}%',
          style: AppText.mono.copyWith(
            fontSize: 12.5,
            color: r.divYield == null ? AppColors.ink3 : AppColors.accent,
          ),
        ),
    };
  }
}

/// A small tappable filter pill; highlighted when [active].
class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = activeColor ?? AppColors.accent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.16) : AppColors.surface2,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: active ? accent : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.ink : AppColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

/// A faint vertical separator between control groups.
class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 20,
        color: AppColors.line,
      );
}
