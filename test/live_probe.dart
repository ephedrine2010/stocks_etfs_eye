import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocks_etfs_eye/app/data_policy.dart';
import 'package:stocks_etfs_eye/data/repository/dashboard_repository.dart';
import 'package:stocks_etfs_eye/data/repository/market_hours.dart';

/// Not a unit test — a live probe. Hits the real CoinGecko/Yahoo/RSS endpoints
/// and prints what came back live vs mock. Run with:
///   flutter test test/live_probe_test.dart
void main() {
  test('probe live sources', () async {
    MarketHours.ensureInitialized();
    final dash = await const DashboardRepository().load();
    for (final m in dash.markets) {
      final leaders = m.leaders.length;
      final firstNews = m.news.isNotEmpty ? m.news.first.headline : '(none)';
      debugPrint(
        '${m.flag} ${m.name.padRight(15)} '
        'quote=${m.quote.source.padRight(10)} '
        'px=${m.quote.price.toStringAsFixed(2).padLeft(10)} '
        'chg=${m.quote.changePct.toStringAsFixed(2).padLeft(6)}% '
        'movers=${m.movers.length} leaders=$leaders '
        'news[0]="$firstNews"',
      );
    }
    // At least CoinGecko (crypto) should be live regardless of platform.
    final crypto = dash.markets.firstWhere((m) => m.id == 'cr');
    expect(crypto.quote.source, 'CoinGecko');
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('probe live AI via proxy (needs proxy on :3000)', () async {
    MarketHours.ensureInitialized();
    final dash = await const DashboardRepository(
      policy: DataPolicy(proxyBaseUrl: 'http://localhost:3000'),
    ).load();
    final brief = dash.brief!;
    debugPrint('brief.source=${brief.source}');
    debugPrint('brief.lead="${brief.lead}"');
    for (final l in brief.lines) {
      debugPrint('  ${l.flag} ${l.name.padRight(10)} ${l.sentiment.name} — ${l.text}');
    }
    final take = dash.marketById('us')!.take!;
    debugPrint('US take.source=${take.source}');
  }, timeout: const Timeout(Duration(seconds: 60)));
}
