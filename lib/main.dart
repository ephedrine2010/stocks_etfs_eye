import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/config.dart';
import 'app/data_policy.dart';
import 'app/env.dart';
import 'app/theme.dart';
import 'auth/cubit/auth_cubit.dart';
import 'firebase_options.dart';
import 'home/cubit/home_cubit.dart';
import 'home/home_page.dart';
import 'services/auth/google_flow.dart';
import 'services/auth_service.dart';
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

  // Google OAuth. A desktop client's "secret" isn't confidential — it ships in
  // the binary and PKCE is what secures the flow — but it still lives in the
  // gitignored .env, never in source. Absent ⇒ sign-in reports unavailable.
  final auth = AuthService(
    flow: googleAuthFlowFor(
      clientId: env['GOOGLE_OAUTH_CLIENT_ID'],
      clientSecret: env['GOOGLE_OAUTH_CLIENT_SECRET'],
    ),
  );

  // The user's added stocks, restored before the first frame so a market dialog
  // opened straight away already has them. A no-op while the store is
  // in-memory; this is where the Firestore load lands.
  final myStocks = MyStocksStore();
  await myStocks.load();

  // The uid decides whose list this is. Wired here rather than in a widget so
  // a sign-in that resolves before the first frame is already applied.
  auth.changes.listen((user) => myStocks.bindUser(user?.uid));

  runApp(
    StocksEyeApp(
      myStocks: myStocks,
      // Gates "My stocks" only — never the dashboard.
      auth: auth,
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

  /// Sign-in. The default has no platform flow, so it reports itself
  /// unavailable — which is exactly what an offline widget test wants.
  final AuthService auth;

  const StocksEyeApp({
    super.key,
    this.repository = const DashboardRepository(),
    this.myStocks,
    this.auth = const AuthService(),
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
        RepositoryProvider<AuthService>.value(value: auth),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                HomeCubit(context.read<DashboardRepository>())..load(),
          ),
          // App-wide because the uid decides where "My stocks" is stored, and
          // the section outlives any one dialog.
          BlocProvider(create: (_) => AuthCubit(auth)),
        ],
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
