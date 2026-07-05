import 'package:equatable/equatable.dart';

import 'schedule.dart';

/// Headline index descriptor. `sahmk` is set only for KSA (official Tadawul id).
class IndexInfo extends Equatable {
  final String label;
  final String symbol;
  final String? sahmk;

  const IndexInfo({required this.label, required this.symbol, this.sahmk});

  @override
  List<Object?> get props => [label, symbol, sahmk];
}

/// A curated instrument reference in a market config (watch / movers / leaders).
/// `yahoo` is the Yahoo ticker (with market suffix) when it differs from `symbol`.
class InstrumentRef extends Equatable {
  final String symbol;
  final String name;
  final String? yahoo;

  const InstrumentRef({required this.symbol, required this.name, this.yahoo});

  /// The ticker to query Yahoo with — the explicit `yahoo` field, else `symbol`.
  String get yahooTicker => yahoo ?? symbol;

  @override
  List<Object?> get props => [symbol, name, yahoo];
}

/// A CoinGecko coin reference (crypto market only).
class CoinRef extends Equatable {
  final String id; // CoinGecko id, e.g. 'bitcoin'
  final String symbol;
  final String name;

  const CoinRef({required this.id, required this.symbol, required this.name});

  @override
  List<Object?> get props => [id, symbol, name];
}

/// The guaranteed-fallback mock quote baked into each market config.
class MockQuote extends Equatable {
  final double price;
  final double changePct;
  final List<double> spark;

  const MockQuote({
    required this.price,
    required this.changePct,
    required this.spark,
  });

  @override
  List<Object?> get props => [price, changePct, spark];
}

/// Static definition of a tracked market. Ported from `backend/markets/*.js`.
class MarketConfig extends Equatable {
  final String id;
  final String name;
  final String city;
  final String flag;
  final String tz;
  final String currency;
  final IndexInfo index;
  final Schedule schedule;

  final String priceSource; // 'yahoo' | 'coingecko' | 'sahmk'
  final String? moversSource; // 'sahmk' when a market opts into live top-movers
  final String newsSource; // 'rss' | 'mock'
  final List<String> newsFeeds;

  final List<InstrumentRef> watch;
  final List<InstrumentRef> movers;
  final List<InstrumentRef> leaders;
  final List<CoinRef> coins; // crypto only

  final MockQuote mock;

  const MarketConfig({
    required this.id,
    required this.name,
    required this.city,
    required this.flag,
    required this.tz,
    required this.currency,
    required this.index,
    required this.schedule,
    required this.priceSource,
    this.moversSource,
    this.newsSource = 'mock',
    this.newsFeeds = const [],
    this.watch = const [],
    this.movers = const [],
    this.leaders = const [],
    this.coins = const [],
    required this.mock,
  });

  bool get always => schedule.always;
  bool get commodity => schedule.commodity;

  @override
  List<Object?> get props => [id, name, index, schedule, priceSource];
}
