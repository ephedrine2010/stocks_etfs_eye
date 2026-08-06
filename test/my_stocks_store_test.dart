import 'package:flutter_test/flutter_test.dart';
import 'package:stocks_etfs_eye/data/models/models.dart';
import 'package:stocks_etfs_eye/services/my_stocks_store.dart';

/// Offline tests over the persistence seam.
///
/// Firebase and `shared_preferences` are both absent here, which is the point:
/// every layer below memory has to fail soft, so these run the store exactly as
/// a user with no network and no account would experience it. If one of them
/// ever throws instead of shrugging, the list vanishes on screen — these catch
/// that without needing either service.
void main() {
  SavedStock stock(String marketId, String symbol) => SavedStock(
    marketId: marketId,
    symbol: symbol,
    name: symbol,
    query: symbol,
    provider: 'yahoo',
  );

  test('signed out, the list is session-only but fully usable', () async {
    final store = MyStocksStore();
    addTearDown(store.dispose);

    expect(store.isPersisting, isFalse);
    expect(await store.add(stock('us', 'PLTR')), isTrue);
    expect(store.forMarket('us').single.symbol, 'PLTR');

    // The same instrument twice is a no-op the caller can report, not a
    // silent duplicate.
    expect(await store.add(stock('us', 'PLTR')), isFalse);
    expect(store.forMarket('us'), hasLength(1));

    await store.remove(stock('us', 'PLTR'));
    expect(store.forMarket('us'), isEmpty);
  });

  test('markets keep their own lists', () async {
    final store = MyStocksStore();
    addTearDown(store.dispose);

    await store.add(stock('us', 'PLTR'));
    await store.add(stock('sa', '1150'));

    expect(store.forMarket('us').single.symbol, 'PLTR');
    expect(store.forMarket('sa').single.symbol, '1150');
    expect(store.forMarket('cr'), isEmpty);
  });

  test('signing in keeps what the session already added', () async {
    final store = MyStocksStore();
    addTearDown(store.dispose);

    await store.add(stock('us', 'PLTR'));
    // Firestore and the mirror both fail here (no Firebase, no prefs), so this
    // is the worst case: the merge is all that stands between the user and
    // losing a stock at the moment they sign in.
    await store.bindUser('uid-1');

    expect(store.isPersisting, isTrue);
    expect(store.forMarket('us').single.symbol, 'PLTR');
  });

  test('signing out drops the account list and stops persisting', () async {
    final store = MyStocksStore();
    addTearDown(store.dispose);

    await store.bindUser('uid-1');
    await store.add(stock('us', 'NVDA'));
    await store.bindUser(null);

    expect(store.isPersisting, isFalse);
    expect(store.forMarket('us'), isEmpty);
  });

  test('binding the same uid twice is a no-op', () async {
    final store = MyStocksStore();
    addTearDown(store.dispose);

    await store.bindUser('uid-1');
    await store.add(stock('us', 'NVDA'));
    await store.bindUser('uid-1');

    expect(store.forMarket('us').single.symbol, 'NVDA');
  });

  test('every change emits, so an open dialog re-reads', () async {
    final store = MyStocksStore();
    addTearDown(store.dispose);

    var ticks = 0;
    final sub = store.changes.listen((_) => ticks++);
    addTearDown(sub.cancel);

    await store.add(stock('us', 'PLTR'));
    await store.remove(stock('us', 'PLTR'));
    await store.bindUser('uid-1');
    await Future<void>.delayed(Duration.zero);

    expect(ticks, 3);
  });

  test('one malformed stored row does not take the list down', () {
    // The shape `_decode` is handed straight out of Firestore or the mirror.
    expect(SavedStock.fromJson({'marketId': 'us'}), isNull);
    expect(
      SavedStock.fromJson({
        'marketId': 'us',
        'symbol': 'PLTR',
        'query': 'PLTR',
        'provider': 'yahoo',
      })?.name,
      'PLTR', // Missing name falls back to the symbol rather than failing.
    );
  });
}
