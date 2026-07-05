import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/config.dart';
import 'firebase_options.dart';
import 'app/data_policy.dart';
import 'app/env.dart';
import 'app/theme.dart';
import 'cubit/clock_cubit.dart';
import 'cubit/dashboard_cubit.dart';
import 'cubit/locale_cubit.dart';
import 'cubit/selection_cubit.dart';
import 'data/repository/dashboard_repository.dart';
import 'data/repository/market_hours.dart';
import 'ui/dashboard_page.dart';

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

  // Restore the last-chosen language before the first frame (no wrong-direction
  // flash). No-op default of English on any platform without a saved value.
  final locale = await LocaleCubit.load();

  runApp(StocksEyeApp(
    initialLocale: locale,
    repository: DashboardRepository(
      policy: DataPolicy(
        proxyBaseUrl: AppConfig.proxyUrl,
        directAiAvailable: hasDirectKey,
      ),
      deepSeekKey: deepSeekKey,
      finnhubKey: finnhubKey,
    ),
  ));
}

class StocksEyeApp extends StatelessWidget {
  /// Injectable so tests can supply an offline (mock-only) repository.
  final DashboardRepository repository;

  /// The language to open in; restored from prefs in [main]. Defaults English.
  final Locale initialLocale;

  const StocksEyeApp({
    super.key,
    this.repository = const DashboardRepository(),
    this.initialLocale = LocaleCubit.en,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                DashboardCubit(context.read<DashboardRepository>())..load(),
          ),
          BlocProvider(create: (_) => ClockCubit()),
          BlocProvider(create: (_) => SelectionCubit()),
          BlocProvider(create: (_) => LocaleCubit(initialLocale)),
        ],
        // Rebuild the whole app when the language flips — this drives the
        // MaterialApp locale, which in turn flips Directionality (LTR ⇄ RTL)
        // for the entire tree.
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) => MaterialApp(
            title: 'Stocks Eye',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            locale: locale,
            supportedLocales: const [LocaleCubit.en, LocaleCubit.ar],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const DashboardPage(),
          ),
        ),
      ),
    );
  }
}
