import 'package:equatable/equatable.dart';

import 'ai.dart';
import 'market.dart';
import 'watch_row.dart';

/// The full payload the UI renders — the Dart equivalent of the JSON returned by
/// the old `GET /api/dashboard`.
class Dashboard extends Equatable {
  final List<Market> markets;
  final List<WatchRow> watchlist;
  final Brief? brief;
  final DateTime asOf;

  const Dashboard({
    required this.markets,
    required this.watchlist,
    this.brief,
    required this.asOf,
  });

  Market? marketById(String id) {
    for (final m in markets) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  List<Object?> get props => [markets, watchlist, brief, asOf];
}
