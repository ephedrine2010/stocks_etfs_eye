import 'package:equatable/equatable.dart';

/// A price reading for a market's headline instrument.
/// Ported from `normalizer.makeQuote`.
class Quote extends Equatable {
  final double price;
  final double changePct;
  final String currency;
  final List<double> spark;
  final String source;
  final DateTime asOf;

  const Quote({
    required this.price,
    required this.changePct,
    required this.source,
    this.currency = 'USD',
    this.spark = const [],
    required this.asOf,
  });

  @override
  List<Object?> get props => [price, changePct, currency, spark, source, asOf];
}
