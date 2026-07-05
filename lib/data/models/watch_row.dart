import 'package:equatable/equatable.dart';

/// A cross-market watchlist row, normalized to USD alongside its native price.
class WatchRow extends Equatable {
  final String id;
  final String flag;
  final String symbol;
  final String name;
  final String native;
  final String usd;
  final double changePct;

  const WatchRow({
    required this.id,
    required this.flag,
    required this.symbol,
    required this.name,
    required this.native,
    required this.usd,
    required this.changePct,
  });

  WatchRow copyWith({String? native, String? usd, double? changePct}) => WatchRow(
    id: id,
    flag: flag,
    symbol: symbol,
    name: name,
    native: native ?? this.native,
    usd: usd ?? this.usd,
    changePct: changePct ?? this.changePct,
  );

  @override
  List<Object?> get props => [id, flag, symbol, name, native, usd, changePct];
}
