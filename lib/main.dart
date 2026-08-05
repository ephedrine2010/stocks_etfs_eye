import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/config.dart';
import 'app/data_policy.dart';
import 'app/env.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'home/cubit/home_cubit.dart';
import 'home/home_page.dart';
import 'services/dashboard_repository.dart';
import 'services/market_hours.dart';
import 'services/my_stocks_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MarketHours.ensureInitialized();

  // Firebase — bring up before the first frame. Fail soft: a Firebase hiccup
  // must never block the dashboard (mirrors the repository's fallback ethos).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Optional at boot; the dashboard runs fine without Firebase.
  }

  // Load a local .env (desktop/mobile). If it carries a DeepSeek key, the app
  // does live AI DIRECTLY — no proxy needed. On Web this is a no-op.
  final env = await loadDotEnv();
  final deepSeekKey = env['DEEPSEEK_API_KEY'];
  final hasDirectKey = deepSeekKey != null && deepSeekKey.isNotEmpty;
  final finnhubKey = env['FINNHUB_API_KEY'];

  // The user's added stocks, restored before the first frame so a market dialog
  // opened straight away already has them. A no-op while the store is
  // in-memory; this is where the Firestore load lands.
  final myStocks = MyStocksStore();
  await myStocks.load();

  runApp(
    StocksEyeApp(
      myStocks: myStocks,
      repository: DashboardRepository(
        policy: DataPolicy(
          proxyBaseUrl: AppConfig.proxyUrl,
          directAiAvailable: hasDirectKey,
        ),
        deepSeekKey: deepSeekKey,
        finnhubKey: finnhubKey,
      ),
    ),
  );
}

class StocksEyeApp extends StatelessWidget {
  /// Injectable so tests can supply an offline (mock-only) repository.
  final DashboardRepository repository;

  /// The user's added stocks. Injectable the same way; when omitted the app
  /// makes its own, so a test gets a clean list without having to build one.
  final MyStocksStore? myStocks;

  const StocksEyeApp({
    super.key,
    this.repository = const DashboardRepository(),
    this.myStocks,
  });

  @override
  Widget build(BuildContext context) {
    final store = myStocks;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: repository),
        if (store != null)
          RepositoryProvider<MyStocksStore>.value(value: store)
        else
          RepositoryProvider<MyStocksStore>(create: (_) => MyStocksStore()),
      ],
      child: BlocProvider(
        create: (context) =>
            HomeCubit(context.read<DashboardRepository>())..load(),
        child: MaterialApp(
          title: 'Stocks Eye',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const HomePage(),
        ),
      ),
    );
  }
}
