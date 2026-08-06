import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/models.dart';

/// Where the user's added stocks live, keyed by market.
///
/// This is the persistence **seam**, and it is the only file that changed when
/// the list stopped being session-only: the cubit and the widgets never learn
/// which layer is backing them.
///
/// Three layers, in order of authority:
/// 1. **In memory** — what's on screen, and the whole story while signed out.
/// 2. **`shared_preferences`** — a per-uid mirror so the list is on screen at
///    launch instead of after a round trip, and survives a Firestore outage.
/// 3. **Firestore** `ephedrine2010/{uid}` — the source of truth across devices.
///
/// Only identity is ever stored ([SavedStock] carries no price), so nothing here
/// can go stale in a way that misleads.
class MyStocksStore {
  final _byMarket = <String, List<SavedStock>>{};
  final _changes = StreamController<void>.broadcast();

  /// Whose list this is. Null while signed out — the list then lives for the
  /// session only, which is why signing in merges it upward rather than
  /// discarding it.
  String? _uid;

  /// Guards against a slow load for a user who has since signed out or changed.
  int _bind = 0;

  /// Emits whenever the list changes, so an open dialog re-reads it.
  Stream<void> get changes => _changes.stream;

  /// Whether additions are being saved anywhere beyond this session.
  bool get isPersisting => _uid != null;

  /// Pull in anything previously saved. Nothing to do until a user is bound —
  /// signed out there is no account to read. Kept async so `main.dart` can go
  /// on awaiting it.
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
    await _persist();
    return true;
  }

  Future<void> remove(SavedStock stock) async {
    _byMarket[stock.marketId]?.removeWhere((s) => s.key == stock.key);
    _changes.add(null);
    await _persist();
  }

  /// Point the store at a signed-in user, or at nobody.
  ///
  /// Called from the auth listener. Signing in **merges** whatever was added
  /// during the signed-out session into the account: those stocks were chosen
  /// deliberately, and having them disappear at the moment of signing in would
  /// read as the app losing them.
  Future<void> bindUser(String? uid) async {
    if (uid == _uid) return;
    final token = ++_bind;
    final pending = _snapshot();
    _uid = uid;

    if (uid == null) {
      // Signed out. The account's list is not ours to show any more; anything
      // added from here is session-only again.
      _byMarket.clear();
      _changes.add(null);
      return;
    }

    // Mirror first — it's local and instant, so the section fills immediately.
    final mirrored = await _readMirror(uid);
    if (token != _bind) return;
    if (mirrored != null) _replaceWith(mirrored);

    // Then the source of truth. A failure here leaves the mirror standing
    // rather than blanking a list the user knows they have.
    final remote = await _readRemote(uid);
    if (token != _bind) return;
    if (remote != null) _replaceWith(remote);

    final merged = _mergeIn(pending);
    _changes.add(null);
    // Write back when signing in brought something up, or when only the mirror
    // answered — either way the two layers should agree afterwards.
    if (merged || remote == null) {
      await _persist();
    } else {
      await _writeMirror(uid, _snapshot());
    }
  }

  Future<void> dispose() => _changes.close();

  // ── layers ────────────────────────────────────────────────────────────────

  /// Write through to both layers. Optimistic: memory already changed and the
  /// UI already reflects it, so a failure here must not be reported as a save.
  Future<void> _persist() async {
    final uid = _uid;
    if (uid == null) return; // Session-only; nothing to write.
    final data = _snapshot();
    await _writeMirror(uid, data);
    await _writeRemote(uid, data);
  }

  DocumentReference<Map<String, dynamic>>? _docFor(String uid) {
    try {
      return FirebaseFirestore.instance.collection('ephedrine2010').doc(uid);
    } catch (_) {
      return null; // Firebase never came up; the mirror carries on alone.
    }
  }

  Future<Map<String, List<SavedStock>>?> _readRemote(String uid) async {
    try {
      final snap = await _docFor(uid)?.get();
      final raw = snap?.data()?['my_stocks'];
      if (raw is! Map) return null;
      return _decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeRemote(String uid, Map<String, List<SavedStock>> data) async {
    try {
      await _docFor(uid)?.set({
        'my_stocks': {
          for (final entry in data.entries)
            entry.key: [for (final s in entry.value) s.toJson()],
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Offline, or rules said no. The mirror still holds it and the next
      // write reconciles — never surface this as a lost stock.
    }
  }

  static String _mirrorKey(String uid) => 'my_stocks:$uid';

  Future<Map<String, List<SavedStock>>?> _readMirror(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_mirrorKey(uid));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? _decode(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeMirror(String uid, Map<String, List<SavedStock>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _mirrorKey(uid),
        jsonEncode({
          for (final entry in data.entries)
            entry.key: [for (final s in entry.value) s.toJson()],
        }),
      );
    } catch (_) {
      // A mirror that can't be written costs a round trip next launch, nothing
      // more. Firestore is still the source of truth.
    }
  }

  // ── shaping ───────────────────────────────────────────────────────────────

  Map<String, List<SavedStock>> _snapshot() => {
    for (final entry in _byMarket.entries)
      if (entry.value.isNotEmpty) entry.key: List.of(entry.value),
  };

  void _replaceWith(Map<String, List<SavedStock>> data) {
    _byMarket
      ..clear()
      ..addAll(data);
  }

  /// Folds [pending] in, skipping anything already there. Returns whether
  /// anything was actually added.
  bool _mergeIn(Map<String, List<SavedStock>> pending) {
    var changed = false;
    for (final entry in pending.entries) {
      final list = _byMarket.putIfAbsent(entry.key, () => <SavedStock>[]);
      for (final stock in entry.value) {
        if (list.any((s) => s.key == stock.key)) continue;
        list.add(stock);
        changed = true;
      }
    }
    return changed;
  }

  /// One malformed row is dropped, never allowed to throw — the rest of the
  /// user's list must survive a single bad record (see `SavedStock.fromJson`).
  static Map<String, List<SavedStock>> _decode(Map<dynamic, dynamic> raw) {
    final out = <String, List<SavedStock>>{};
    for (final entry in raw.entries) {
      final marketId = entry.key;
      final rows = entry.value;
      if (marketId is! String || rows is! List) continue;
      final parsed = <SavedStock>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final stock = SavedStock.fromJson(Map<String, dynamic>.from(row));
        if (stock != null) parsed.add(stock);
      }
      if (parsed.isNotEmpty) out[marketId] = parsed;
    }
    return out;
  }
}
