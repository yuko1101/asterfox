import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../music/music_data/music_data.dart';
import '../music/manager/music_manager.dart';
import 'app_scopes.dart';
import 'database.dart';

class SongHistoryData {
  static String get _scope => AppDatabase.userScopeOf(AppScopes.history);

  /// Entries in the order they were played.
  static final List<Map<String, dynamic>> _data = [];

  /// Bumped whenever [_data] changes, in place included.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static AppDatabase get _db => AppDatabase.instance;

  static Future<void> init(MusicManager manager) async {
    await reloadDatabase();

    // when song is played, add it to history.
    manager.audioStateManager.currentSongNotifier.addListener(() {
      if (manager.state.currentSong != null) {
        addAndSave(manager.state.currentSong!);
      }
    });
  }

  /// Loads the stored history into memory.
  static Future<void> reloadDatabase() async {
    final rows = await (_db.select(_db.documents)
          ..where((table) => table.scope.equals(_scope))
          ..orderBy([(table) => OrderingTerm.asc(table.rowId)]))
        .get();
    _data
      ..clear()
      ..addAll(rows.map(
          (row) => Map<String, dynamic>.from(jsonDecode(row.json) as Map)));
    revision.value = revision.value + 1;
  }

  static Future<void> addAndSave(MusicData song) async {
    final entry = {
      "audioId": song.audioId,
      "title": song.title,
      "author": song.author,
      "lastPlayed": DateTime.now().millisecondsSinceEpoch,
    };
    final index =
        _data.indexWhere((element) => element["audioId"] == song.audioId);
    if (index == -1) {
      _data.add(entry);
    } else {
      _data[index] = entry;
    }
    revision.value = revision.value + 1;
    await _save(entry);
  }

  static Future<void> _save(Map<String, dynamic> entry) async {
    await _db.into(_db.documents).insert(
          DocumentsCompanion.insert(
            scope: _scope,
            id: entry["audioId"] as String,
            json: jsonEncode(entry),
          ),
          onConflict: DoUpdate(
            (old) => DocumentsCompanion.insert(
              scope: _scope,
              id: entry["audioId"] as String,
              json: jsonEncode(entry),
            ),
            target: [_db.documents.scope, _db.documents.id],
          ),
        );
  }

  static List<Map<String, dynamic>> getAll() => _data;

  static Future<void> remove(String audioId) async {
    _data.removeWhere((element) => element["audioId"] == audioId);
    revision.value = revision.value + 1;
    await (_db.delete(_db.documents)
          ..where((table) =>
              table.scope.equals(_scope) & table.id.equals(audioId)))
        .go();
  }

  static Future<void> removeMultiple(List<String> audioIds) async {
    _data.removeWhere((element) => audioIds.contains(element["audioId"]));
    revision.value = revision.value + 1;
    await (_db.delete(_db.documents)
          ..where(
              (table) => table.scope.equals(_scope) & table.id.isIn(audioIds)))
        .go();
  }

  /// Replaces the stored history, for example when importing an export.
  static Future<void> replaceAll(List<dynamic> entries) async {
    _data
      ..clear()
      ..addAll(entries.map((e) => Map<String, dynamic>.from(e as Map)));
    await _db.transaction(() async {
      await (_db.delete(_db.documents)
            ..where((table) => table.scope.equals(_scope)))
          .go();
      for (final entry in _data) {
        await _save(entry);
      }
    });
    revision.value = revision.value + 1;
  }

  /// The stored entries, in the shape the cloud stores them.
  static List<Map<String, dynamic>> getStoredData() => _data;

  static Future<void> clear() async {
    _data.clear();
    revision.value = revision.value + 1;
    await (_db.delete(_db.documents)
          ..where((table) => table.scope.equals(_scope)))
        .go();
  }
}

extension SongHistoryDataExtension on MusicData {
  int? get lastPlayed {
    final song = SongHistoryData.getAll()
        .firstWhere((element) => element["audioId"] == audioId,
            orElse: () => {});
    return song["lastPlayed"] as int?;
  }

  MusicData<T> renew<T extends Caching>({required T caching}) {
    return MusicData.fromJson(
      json: toJson(),
      caching: caching,
    );
  }
}
