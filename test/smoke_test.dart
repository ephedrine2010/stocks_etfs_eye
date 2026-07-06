import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocks_etfs_eye/app/data_policy.dart';
import 'package:stocks_etfs_eye/cubit/locale_cubit.dart';
import 'package:stocks_etfs_eye/data/repository/dashboard_repository.dart';
import 'package:stocks_etfs_eye/data/repository/market_hours.dart';
import 'package:stocks_etfs_eye/main.dart';

void main() {
  testWidgets('dashboard renders brand, brief, tiles and tables on mock data',
      (tester) async {
    MarketHours.ensureInitialized();
    // A desktop-ish surface so the side-by-side layout and grid lay out.
    tester.view.physicalSize = const Size(1300, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const StocksEyeApp(
      repository: DashboardRepository(policy: DataPolicy(offline: true)),
    ));
    // Let the async mock repository load resolve (avoid pumpAndSettle — the
    // ClockCubit's periodic timer never settles).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Stocks Eye'), findsOneWidget);
    expect(find.text('AI MORNING BRIEF'), findsOneWidget);
    // A market tile (USA) rendered.
    expect(find.text('United States'), findsWidgets);
    // Detail panel (default selection = USA → S&P 500) and a table header.
    expect(find.text('Top movers · session'.toUpperCase()), findsOneWidget);
    expect(find.text('Watchlist · normalized to USD'.toUpperCase()),
        findsOneWidget);

    // Dispose to cancel the ClockCubit timer so the test ends cleanly.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders on a narrow (mobile) surface without overflow',
      (tester) async {
    MarketHours.ensureInitialized();
    tester.view.physicalSize = const Size(390, 5200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const StocksEyeApp(
      repository: DashboardRepository(policy: DataPolicy(offline: true)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Stocks Eye'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders in Arabic (RTL) without overflow and can toggle back',
      (tester) async {
    MarketHours.ensureInitialized();
    SharedPreferences.setMockInitialValues({}); // so the toggle can persist
    tester.view.physicalSize = const Size(390, 5200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const StocksEyeApp(
      initialLocale: LocaleCubit.ar,
      repository: DashboardRepository(policy: DataPolicy(offline: true)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The whole tree is right-to-left in Arabic.
    expect(Directionality.of(tester.element(find.byType(Scaffold))),
        TextDirection.rtl);
    // Arabic chrome is rendered (translated market status label) and the longer
    // Arabic strings don't overflow the 390px surface.
    expect(find.text('الأسواق — الحالة المباشرة'), findsOneWidget);
    // AI brief *content* is bilingual: the Arabic side of a mock brief line shows.
    expect(find.text('العقود الآجلة أقوى؛ أسهم التقنية الكبرى تتصدر قبل الافتتاح.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tapping the EN segment flips the app back to English (LTR).
    await tester.tap(find.text('EN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Markets — live status'.toUpperCase()), findsOneWidget);
    // The same brief line now shows its English text — no refetch needed.
    expect(find.text('Futures firmer; megacap tech leads pre-market.'),
        findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(Scaffold))),
        TextDirection.ltr);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
