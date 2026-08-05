import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocks_etfs_eye/app/data_policy.dart';
import 'package:stocks_etfs_eye/app/theme.dart';
import 'package:stocks_etfs_eye/data/models/models.dart';
import 'package:stocks_etfs_eye/main.dart';
import 'package:stocks_etfs_eye/market_details/market_details_dialog.dart';
import 'package:stocks_etfs_eye/market_details/widgets/my_stocks_table.dart';
import 'package:stocks_etfs_eye/markets_list/markets_list_view.dart';
import 'package:stocks_etfs_eye/screen_all_markets/screen_all_markets_view.dart';
import 'package:stocks_etfs_eye/services/dashboard_repository.dart';
import 'package:stocks_etfs_eye/services/market_hours.dart';
import 'package:stocks_etfs_eye/services/my_stocks_store.dart';
import 'package:stocks_etfs_eye/shared/widgets/price_chart.dart';

/// Offline, deterministic widget tests over the mock repository.
///
/// The narrow cases assert no overflow at 320–390 px — the regression that
/// catches most layout mistakes.
void main() {
  /// Pump the app and let the async mock load resolve. Avoids `pumpAndSettle`:
  /// the markets-list ticker is periodic and never settles.
  Future<void> pumpApp(WidgetTester tester, {required Size size}) async {
    MarketHours.ensureInitialized();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const StocksEyeApp(
        repository: DashboardRepository(policy: DataPolicy(offline: true)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('home renders the brand, the screener and the market tiles', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1300, 2400));

    expect(find.text('Stocks Eye'), findsOneWidget);
    // Both sections of the new home page, in order.
    expect(find.byType(ScreenAllMarketsView), findsOneWidget);
    expect(find.byType(MarketsListView), findsOneWidget);
    expect(find.text('SCREEN — ALL MARKETS'), findsOneWidget);
    expect(find.text('MARKETS — LIVE STATUS'), findsOneWidget);
    // A market tile (USA) rendered.
    expect(find.text('United States'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Dispose to cancel the ticker so the test ends cleanly.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping a market tile opens its details dialog', (tester) async {
    await pumpApp(tester, size: const Size(1300, 2400));

    expect(find.byType(MarketDetailsDialog), findsNothing);
    await tester.tap(find.text('United States').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MarketDetailsDialog), findsOneWidget);
    // The dialog shows that market's index and its sections.
    expect(find.text('S&P 500'), findsWidgets);
    expect(find.text('MY STOCKS · USD'), findsOneWidget);
    expect(find.text('TOP MOVERS · SESSION'), findsOneWidget);
    expect(find.text('LATEST · NEWS & SENTIMENT'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('my stocks starts empty and hides Add when search is offline', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1300, 2400));

    await tester.tap(find.text('United States').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The offline policy can't reach Yahoo, so the section says so rather than
    // offering a search box that could only ever come back empty.
    expect(find.text('MY STOCKS · USD'), findsOneWidget);
    expect(find.text('Search isn\'t available here'), findsOneWidget);
    expect(find.text('Add stock'), findsNothing);
    expect(find.byType(MyStocksTable), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a saved stock renders in the my-stocks table', (tester) async {
    // Seed the store the way the Firestore load will, then confirm the row
    // shows even though the offline policy can price nothing.
    final store = MyStocksStore();
    await store.add(
      const SavedStock(
        marketId: 'us',
        symbol: 'PLTR',
        name: 'Palantir Technologies',
        query: 'PLTR',
        provider: 'yahoo',
      ),
    );

    MarketHours.ensureInitialized();
    tester.view.physicalSize = const Size(1300, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      StocksEyeApp(
        repository: const DashboardRepository(
          policy: DataPolicy(offline: true),
        ),
        myStocks: store,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('United States').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MyStocksTable), findsOneWidget);
    expect(find.text('PLTR'), findsWidgets);
    expect(find.text('Palantir Technologies'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the open/closed filter narrows the market tiles', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1300, 2400));

    // Crypto is always open, so "Open · n" always has at least one market.
    final openPill = find.textContaining(RegExp(r'^Open · \d'));
    expect(openPill, findsOneWidget);
    await tester.tap(openPill);
    await tester.pump();

    expect(find.text('Crypto'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders on a narrow (mobile) surface without overflow', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(390, 5200));

    expect(find.text('Stocks Eye'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders at 320 px without overflow', (tester) async {
    await pumpApp(tester, size: const Size(320, 6000));

    expect(find.text('Stocks Eye'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the details dialog fits a narrow surface', (tester) async {
    await pumpApp(tester, size: const Size(390, 5200));

    await tester.tap(find.text('United States').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MarketDetailsDialog), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the price chart draws a curve at 320 px without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // A hand-built series, not a mock source: the app never fabricates history,
    // but a test needs a deterministic one to lay out.
    final start = DateTime(2026, 1, 1);
    final history = PriceHistory(
      symbol: 'TEST',
      name: 'Test Instrument',
      range: HistoryRange.months3,
      currency: 'USD',
      source: 'Yahoo',
      points: [
        for (var i = 0; i < 60; i++)
          PricePoint(start.add(Duration(days: i)), 100 + (i % 7) * 1.5),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: PriceChart(history: history),
          ),
        ),
      ),
    );
    await tester.pump();

    // The readout shows the window's own change, and the axis its bounds.
    expect(find.byType(PriceChart), findsOneWidget);
    expect(find.text('1 Jan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
