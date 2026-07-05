import 'package:equatable/equatable.dart';

import 'ai.dart';
import 'instruments.dart';
import 'market_config.dart';
import 'news_item.dart';
import 'quote.dart';
import 'schedule.dart';

/// A fully-built market: its static config plus the runtime data assembled by
/// the repository (quote, movers, leaders, news, take). Equivalent to the object
/// `dashboard.js` returns per market.
class Market extends Equatable {
  final MarketConfig config;
  final Quote quote;
  final List<Mover> movers;
  final List<Leader> leaders;
  final List<NewsItem> news;
  final Take? take;

  const Market({
    required this.config,
    required this.quote,
    this.movers = const [],
    this.leaders = const [],
    this.news = const [],
    this.take,
  });

  // Convenience passthroughs so the UI reads `market.name` etc.
  String get id => config.id;
  String get name => config.name;
  String get city => config.city;
  String get flag => config.flag;
  String get tz => config.tz;
  String get currency => config.currency;
  String get indexLabel => config.index.label;
  Schedule get schedule => config.schedule;
  bool get always => config.always;
  bool get commodity => config.commodity;
  List<double> get spark => quote.spark;
  List<String> get watchSymbols =>
      config.watch.map((w) => w.symbol).toList(growable: false);

  Market copyWith({
    Quote? quote,
    List<Mover>? movers,
    List<Leader>? leaders,
    List<NewsItem>? news,
    Take? take,
  }) => Market(
    config: config,
    quote: quote ?? this.quote,
    movers: movers ?? this.movers,
    leaders: leaders ?? this.leaders,
    news: news ?? this.news,
    take: take ?? this.take,
  );

  @override
  List<Object?> get props => [config, quote, movers, leaders, news, take];
}
