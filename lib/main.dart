import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/config.dart';
import 'app/data_policy.dart';
import 'app/env.dart';
import 'app/theme.dart';
import 'cubit/clock_cubit.dart';
import 'cubit/dashboard_cubit.dart';
import 'cubit/selection_cubit.dart';
import 'data/repository/dashboard_repository.dart';
import 'data/repository/market_hours.dart';
import 'ui/dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MarketHours.ensureInitialized();

  // Load a local .env (desktop/mobile). If it carries a DeepSeek key, the app
  // does live AI DIRECTLY — no proxy needed. On Web this is a no-op.
  final env = await loadDotEnv();
  final deepSeekKey = env['DEEPSEEK_API_KEY'];
  final hasDirectKey = deepSeekKey != null && deepSeekKey.isNotEmpty;
  final finnhubKey = env['FINNHUB_API_KEY'];

  runApp(StocksEyeApp(
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

  const StocksEyeApp({super.key, this.repository = const DashboardRepository()});

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
        ],
        child: MaterialApp(
          title: 'Stocks Eye',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const DashboardPage(),
        ),
      ),
    );
  }
}
