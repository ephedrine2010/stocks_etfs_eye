import 'package:equatable/equatable.dart';

/// A single top-mover row (per-market stock/ETF/coin).
class Mover extends Equatable {
  final String symbol;
  final String name;
  final double changePct;

  /// Present for live sources; null for the mock movers.
  final double? price;

  const Mover({
    required this.symbol,
    required this.name,
    required this.changePct,
    this.price,
  });

  @override
  List<Object?> get props => [symbol, name, changePct, price];
}

/// Dividend summary attached to a leading stock. Ported from
/// `{ yield, annual, exDate, frequency }`. A genuine non-payer is `null`
/// (the UI shows "—"), distinct from missing data.
class Dividend extends Equatable {
  final double yield; // percent, e.g. 2.31 => 2.31%
  final double annual;
  final String? exDate;
  final String? frequency;

  const Dividend({
    required this.yield,
    required this.annual,
    this.exDate,
    this.frequency,
  });

  @override
  List<Object?> get props => [yield, annual, exDate, frequency];
}

/// A heavyweight "leading stock" — bellwether that drives the index,
/// priced live + carrying an optional dividend summary.
class Leader extends Equatable {
  final String symbol;
  final String name;
  final double price;
  final double changePct;
  final Dividend? dividend;

  const Leader({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePct,
    this.dividend,
  });

  @override
  List<Object?> get props => [symbol, name, price, changePct, dividend];
}
