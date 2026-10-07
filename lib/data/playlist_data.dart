import 'dart:convert';

import 'package:drift/drift.dart';

import '../music/playlist/playlist.dart';
import '../system/firebase/cloud_firestore.dart';
import 'app_scopes.dart';
import 'database.dart';

class PlaylistsData {
  static String get _scope => AppDatabase.userScopeOf(AppScopes.playlists);

  /// The stored playlists, keyed by id.
  static final Map<String, Map<String, dynamic>> _data = {};

  static AppDatabase get _db => AppDatabase.instance;

  static Future<void> init() async {
    await reloadDatabase();
  }

  /// Loads the stored playlists into memory.
  static Future<void> reloadDatabase() async {
    final rows = await (_db.select(_db.documents)
          ..where((table) => table.scope.equals(_scope)))
        .get();
    _data
      ..clear()
      ..addAll({
        for (final row in rows)
          row.id: Map<String, dynamic>.from(jsonDecode(row.json) as Map)
      });
  }

  static Future<void> addAndSave(AppPlaylist playlist) async {
    final entry = playlist.toJson();
    _data[playlist.id] = entry;
    await _upsert(playlist.id, entry);
    await CloudFirestoreManager.addOrUpdatePlaylists([playlist]);
  }

  static Future<void> _upsert(String id, Map<String, dynamic> entry) async {
    await _db.into(_db.documents).insert(
          DocumentsCompanion.insert(
            scope: _scope,
            id: id,
            json: jsonEncode(entry),
          ),
          onConflict: DoUpdate(
            (old) => DocumentsCompanion.insert(
              scope: _scope,
              id: id,
              json: jsonEncode(entry),
            ),
            target: [_db.documents.scope, _db.documents.id],
          ),
        );
  }

  static List<AppPlaylist> getAll() {
    return _data.values.map((p) => AppPlaylist.fromJson(p)).toList();
  }

  static AppPlaylist getById(String id) {
    return AppPlaylist.fromJson(_data[id]!);
  }

  static Future<void> remove(String id) async {
    _data.remove(id);
    await _delete(id);
    await CloudFirestoreManager.removePlaylists([id]);
  }

  static Future<void> removeMultiple(List<String> ids) async {
    for (final id in ids) {
      _data.remove(id);
    }
    await (_db.delete(_db.documents)
          ..where((table) => table.scope.equals(_scope) & table.id.isIn(ids)))
        .go();
    await CloudFirestoreManager.removePlaylists(ids);
  }

  static Future<void> _delete(String id) async {
    await (_db.delete(_db.documents)
          ..where((table) => table.scope.equals(_scope) & table.id.equals(id)))
        .go();
  }

  /// Applies a playlist as received from the cloud. A null [json] removes it.
  static Future<void> applyRemoteChange(
      {required String playlistId, Map<String, dynamic>? json}) async {
    if (json == null) {
      _data.remove(playlistId);
      await _delete(playlistId);
    } else {
      _data[playlistId] = json;
      await _upsert(playlistId, json);
    }
  }

  /// Replaces the stored playlists, for example when importing an export.
  static Future<void> replaceAll(Map<String, dynamic> json) async {
    _data
      ..clear()
      ..addAll({
        for (final entry in json.entries)
          entry.key: Map<String, dynamic>.from(entry.value as Map)
      });
    await _db.transaction(() async {
      await (_db.delete(_db.documents)
            ..where((table) => table.scope.equals(_scope)))
          .go();
      for (final entry in _data.entries) {
        await _upsert(entry.key, entry.value);
      }
    });
  }

  /// The stored entries, in the shape the cloud stores them.
  static Map<String, dynamic> getStoredData() => _data;

  static Future<void> clear() async {
    _data.clear();
    await (_db.delete(_db.documents)
          ..where((table) => table.scope.equals(_scope)))
        .go();
    await CloudFirestoreManager.removeAllPlaylists();
  }
}
