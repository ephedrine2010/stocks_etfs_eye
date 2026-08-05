import 'package:equatable/equatable.dart';

import '../../data/models/models.dart';

/// One market's user-added stocks: the saved identities, and the live rows
/// fetched for them.
///
/// [saved] and [rows] are deliberately separate. `saved` is what the user chose
/// and always renders; `rows` is what a source could actually price right now.
/// A saved stock with no row shows as unpriced rather than vanishing — losing a
/// row the user explicitly added would look like the app forgot it.
class MyStocksState extends Equatable {
  final List<SavedStock> saved;
  final List<Leader> rows;

  /// Live rows are in flight.
  final bool loading;

  /// This platform can reach the market's search source at all.
  final bool canSearch;

  const MyStocksState({
    this.saved = const [],
    this.rows = const [],
    this.loading = false,
    this.canSearch = false,
  });

  bool get isEmpty => saved.isEmpty;

  /// The live row for a saved stock, or null when it couldn't be priced.
  Leader? rowFor(SavedStock stock) {
    for (final row in rows) {
      if (row.symbol == stock.symbol) return row;
    }
    return null;
  }

  MyStocksState copyWith({
    List<SavedStock>? saved,
    List<Leader>? rows,
    bool? loading,
    bool? canSearch,
  }) => MyStocksState(
    saved: saved ?? this.saved,
    rows: rows ?? this.rows,
    loading: loading ?? this.loading,
    canSearch: canSearch ?? this.canSearch,
  );

  @override
  List<Object?> get props => [saved, rows, loading, canSearch];
}
