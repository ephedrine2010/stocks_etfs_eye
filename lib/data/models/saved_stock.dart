import 'package:equatable/equatable.dart';

/// A stock the user searched for and added to a market's "My stocks" list.
///
/// Carries **identity only** — never a price, change or dividend. Those are
/// re-fetched live every time the list is shown, for the same reason the price
/// curves never mock: a stored number would be read as a current one.
///
/// [query] is the id the source is actually called with, captured from the
/// search result rather than derived. That keeps the "never guess a ticker"
/// rule intact — nothing in the app turns `1150` into `1150.SR` by assumption.
class SavedStock extends Equatable {
  /// The market this was added under (`MarketConfig.id`).
  final String marketId;

  /// What the user sees: `1150`, `NVDA`, `ADA`.
  final String symbol;

  /// Company / coin name.
  final String name;

  /// The id handed to the source: `1150.SR`, `NVDA`, `cardano`.
  final String query;

  /// Which adapter serves it — `yahoo` or `coingecko`.
  final String provider;

  const SavedStock({
    required this.marketId,
    required this.symbol,
    required this.name,
    required this.query,
    required this.provider,
  });

  /// Stable identity across a market's list — two entries for the same
  /// instrument are the same row regardless of how the name came back.
  String get key => '$provider:$query';

  Map<String, dynamic> toJson() => {
    'marketId': marketId,
    'symbol': symbol,
    'name': name,
    'query': query,
    'provider': provider,
  };

  /// Returns null for a malformed record rather than throwing — a single bad
  /// entry in storage must not take the whole list down with it.
  static SavedStock? fromJson(Map<String, dynamic> json) {
    final marketId = json['marketId'];
    final symbol = json['symbol'];
    final query = json['query'];
    final provider = json['provider'];
    if (marketId is! String ||
        symbol is! String ||
        query is! String ||
        provider is! String) {
      return null;
    }
    return SavedStock(
      marketId: marketId,
      symbol: symbol,
      name: json['name'] is String ? json['name'] as String : symbol,
      query: query,
      provider: provider,
    );
  }

  @override
  List<Object?> get props => [marketId, symbol, name, query, provider];
}
