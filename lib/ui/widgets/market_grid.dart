import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import 'market_tile.dart';

/// Responsive grid of market tiles — `repeat(auto-fit, minmax(172px, 1fr))`
/// from the old CSS, reproduced with a LayoutBuilder + Wrap.
class MarketGrid extends StatelessWidget {
  final List<Market> markets;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const MarketGrid({
    super.key,
    required this.markets,
    required this.selectedId,
    required this.onSelect,
  });

  static const _gap = 12.0;
  static const _minTile = 172.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        var cols = ((w + _gap) / (_minTile + _gap)).floor();
        cols = cols.clamp(1, markets.length);
        final tileW = (w - (cols - 1) * _gap) / cols;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final m in markets)
              SizedBox(
                width: tileW,
                child: MarketTile(
                  market: m,
                  selected: m.id == selectedId,
                  onTap: () => onSelect(m.id),
                ),
              ),
          ],
        );
      },
    );
  }
}
