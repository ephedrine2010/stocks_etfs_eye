import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocks_etfs_eye/data/config/markets.dart';
import 'package:stocks_etfs_eye/data/models/models.dart';
import 'package:stocks_etfs_eye/services/my_stocks_service.dart';

/// Not a unit test — a live probe for the "My stocks" search. Hits the real
/// Yahoo / CoinGecko lookup endpoints and prints what came back. Excluded from
/// `flutter test` by filename (no `_test` suffix). Run with:
///   flutter test test/search_probe.dart
/// Sync helper: `yield` is a reserved word inside an async body, so
/// `r.dividend?.yield` can't be written directly in the test itself.
String _divLabel(Leader r) => r.dividend?.yield.toStringAsFixed(2) ?? '—';

void main() {
  const service = MyStocksService();

  /// A market's search results for [query], printed and returned.
  Future<List<SavedStock>> probe(String marketId, String query) async {
    final market = marketConfigById(marketId)!;
    final hits = await service.search(market, query);
    debugPrint(
      '${market.flag} ${market.name.padRight(14)} "$query" → ${hits.length} hit(s)',
    );
    for (final h in hits.take(5)) {
      debugPrint('    ${h.symbol.padRight(10)} ${h.query.padRight(12)} ${h.name}');
    }
    return hits;
  }

  test('search returns results scoped to each market', () async {
    final us = await probe('us', 'palantir');
    final sa = await probe('sa', 'alinma');
    final eg = await probe('eg', 'bank');
    final cn = await probe('cn', 'ping an');
    final cr = await probe('cr', 'cardano');

    // Ticker-style queries on the thinner exchanges, where a plain word gets
    // crowded out of Yahoo's global top-20 by larger listings.
    final egTicker = await probe('eg', 'COMI');
    await probe('cn', '600519');
    await probe('cn', 'kweichow');
    await probe('ae', 'EMAAR');

    // Yahoo's search index has no EGX coverage at all, so Egypt depends
    // entirely on the verified ticker probe.
    expect(egTicker, isNotEmpty, reason: 'ticker fallback must rescue EGX');
    expect(egTicker.first.query, 'COMI.CA');
    expect(egTicker.first.symbol, 'COMI');

    // Every equity hit must belong to its market's own exchange — the rule that
    // keeps an added row's currency and session labels truthful.
    expect(us.every((h) => !h.query.contains('.')), isTrue,
        reason: 'US results must be unsuffixed tickers');
    expect(sa.every((h) => h.query.endsWith('.SR')), isTrue,
        reason: 'KSA results must be .SR');
    expect(eg.every((h) => h.query.endsWith('.CA')), isTrue,
        reason: 'Egypt results must be .CA');
    expect(cn.every((h) => h.query.endsWith('.SS') || h.query.endsWith('.SZ')),
        isTrue, reason: 'China results must be .SS/.SZ');
    expect(cr.every((h) => h.provider == 'coingecko'), isTrue);

    // The display symbol drops the suffix, matching the curated rows.
    for (final h in sa) {
      expect(h.symbol.contains('.'), isFalse);
    }

    // At least the two most reliable lookups should find something.
    expect(us, isNotEmpty, reason: 'Yahoo search found no US match');
    expect(cr, isNotEmpty, reason: 'CoinGecko search found no coin');
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('an added stock can be priced and charted', () async {
    final market = marketConfigById('us')!;
    final hits = await service.search(market, 'palantir');
    expect(hits, isNotEmpty);

    final rows = await service.rows(market, [hits.first]);
    for (final r in rows) {
      debugPrint(
        'row ${r.symbol.padRight(8)} px=${r.price.toStringAsFixed(2)} '
        'chg=${r.changePct.toStringAsFixed(2)}% '
        'div=${_divLabel(r)}',
      );
    }
    expect(rows, isNotEmpty, reason: 'an added stock must price like a leader');
    expect(rows.first.price, greaterThan(0));
  }, timeout: const Timeout(Duration(seconds: 90)));
}
