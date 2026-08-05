import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocks_etfs_eye/data/config/markets.dart';
import 'package:stocks_etfs_eye/data/models/models.dart';
import 'package:stocks_etfs_eye/services/price_history_service.dart';

/// Not a unit test — a live probe for [PriceHistoryService]. Hits real Yahoo /
/// CoinGecko and prints the point count + window change per range. Run with:
///   flutter test test/history_probe.dart
///
/// A range that prints "N.A." is the honest answer for that instrument — the
/// service never substitutes a mock series.
void main() {
  const service = PriceHistoryService();

  Future<void> probe(HistoryTarget target) async {
    for (final range in HistoryRange.values) {
      final h = await service.fetch(target, range);
      debugPrint(
        '${target.symbol.padRight(10)} ${range.label.padRight(3)} '
        '${h == null ? 'N.A.' : '${h.points.length.toString().padLeft(4)} pts  '
            'first=${h.points.first.time}  last=${h.points.last.time}  '
            'chg=${h.changePct?.toStringAsFixed(2)}%'}',
      );
    }
  }

  test('probe an equity curve (Yahoo)', () async {
    final us = kMarkets.firstWhere((m) => m.id == 'us');
    final target = HistoryTarget.forSymbol(us, us.movers.first.symbol);
    expect(target, isNotNull, reason: 'a configured mover must resolve');
    await probe(target!);
    // Daily windows are the reliable ones; intraday can be empty out of hours.
    expect(await service.fetch(target, HistoryRange.months6), isNotNull);
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('probe a crypto curve (CoinGecko)', () async {
    final cr = kMarkets.firstWhere((m) => m.id == 'cr');
    final target = HistoryTarget.forSymbol(cr, cr.coins.first.symbol);
    expect(target, isNotNull, reason: 'a configured coin must resolve');
    await probe(target!);
    expect(await service.fetch(target, HistoryRange.month), isNotNull);
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('an unknown symbol resolves to nothing, never a guessed ticker', () {
    final us = kMarkets.firstWhere((m) => m.id == 'us');
    expect(HistoryTarget.forSymbol(us, 'NOT_A_TICKER'), isNull);
  });
}
