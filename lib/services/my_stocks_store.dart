import 'dart:async';

import '../data/models/models.dart';

/// Where the user's added stocks live, keyed by market.
///
/// This is the persistence **seam**. Today it holds the list in memory for the
/// session; Firestore (`ephedrine2010/{uid}`) plus a local mirror slot in behind
/// this same surface, so the cubit and the widgets never learn which is backing
/// them — adding real persistence stays an edit to ONE file, the way swapping a
/// data source is.
///
/// Only identity is ever stored ([SavedStock] carries no price), so nothing here
/// can go stale in a way that misleads.
class MyStocksStore {
  final _byMarket = <String, List<SavedStock>>{};
  final _changes = StreamController<void>.broadcast();

  /// Emits whenever the list changes, so an open dialog re-reads it.
  Stream<void> get changes => _changes.stream;

  /// Pull in anything previously saved. A no-op while the store is in-memory —
  /// callers should already treat it as async so the Firestore version drops in
  /// without touching them.
  Future<void> load() async {}

  List<SavedStock> forMarket(String marketId) =>
      List.unmodifiable(_byMarket[marketId] ?? const <SavedStock>[]);

  /// Adds unless the same instrument is already saved. Returns false in that
  /// case so the caller can say "already added" instead of silently no-oping.
  Future<bool> add(SavedStock stock) async {
    final list = _byMarket.putIfAbsent(stock.marketId, () => <SavedStock>[]);
    if (list.any((s) => s.key == stock.key)) return false;
    list.add(stock);
    _changes.add(null);
    return true;
  }

  Future<void> remove(SavedStock stock) async {
    _byMarket[stock.marketId]?.removeWhere((s) => s.key == stock.key);
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
