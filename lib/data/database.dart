import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../main.dart';
import 'app_scopes.dart';

part 'database.g.dart';

/// A key-value store. Values are JSON so that the shape of a single setting can
/// be anything this app reads.
class SettingsEntries extends Table {
  TextColumn get scope => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {scope, key};
}

/// An entry of a JSON object whose keys are string ids.
///
/// "music.json" (scope "songs"), "playlists.json" (scope "playlists") and the
/// entries of "history.json" (scope "history", where the value keeps the
/// entry's own fields next to "audioId").
class Documents extends Table {
  TextColumn get scope => text()();
  TextColumn get id => text()();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {scope, id};
}

@DriftDatabase(tables: [SettingsEntries, Documents])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults()
      : super(driftDatabase(
          name: 'asterfox',
          native: DriftNativeOptions(databasePath: _databasePath),
          // drift persists on the web with sqlite3.wasm and drift_worker.js in
          // web/. Without them it falls back to an in-memory database, which is
          // the same behavior as the config files it replaces.
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ));

  static Future<String> _databasePath() async {
    // `localPath` of main.dart keeps the historical location ("Asterfox"
    // subdirectory on desktop).
    final dir = localPath;
    if (!Directory(dir).existsSync()) {
      await Directory(dir).create(recursive: true);
    }
    return '$dir/asterfox.sqlite';
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 stored the colors under "__custom_colors", before the scopes
          // below were grouped under the device scope.
          if (from < 2) {
            await customStatement('''
              UPDATE settings_entries SET scope = ?
               WHERE scope = '__custom_colors'
            ''', [AppScopes.customColors]);
          }
        },
      );

  static AppDatabase? _instance;

  /// The opened database. Only valid after [open] has completed.
  static AppDatabase get instance => _instance!;

  /// The id of the signed in user, or null when no user is signed in.
  static String? currentUser;

  /// The scope of the rows of [dataScope] that belong to the current user.
  static String userScopeOf(String dataScope) =>
      '${currentUser ?? AppScopes.local}/$dataScope';

  /// Opens this database and imports the legacy JSON files if they exist.
  static Future<AppDatabase> open() async {
    if (_instance != null) return _instance!;
    final db = AppDatabase.defaults();
    await db.importLegacyJsonFiles(localPath);
    _instance = db;
    return db;
  }

  /// Imports the JSON files this app used to store its data in.
  ///
  /// A row that is already stored wins, so this can run on every start. The
  /// web build never had files to import.
  Future<void> importLegacyJsonFiles(String path) async {
    if (kIsWeb) return;

    // "music.json" and "playlists.json" both used their document key as the id.
    await _importObject(
      File('$path/music.json'),
      scope: userScopeOf(AppScopes.songs),
    );
    await _importObject(
      File('$path/playlists.json'),
      scope: userScopeOf(AppScopes.playlists),
    );

    // "history.json" was stored as {"history": [...]}.
    await _importObject(
      File('$path/history.json'),
      scope: userScopeOf(AppScopes.history),
      rootKey: "history",
    );

    // settings.json, device_settings.json and custom_colors.json are all single
    // objects whose entries become key-value pairs.
    await _importSettings(File('$path/settings.json'), AppScopes.settings);
    await _importSettings(
        File('$path/device_settings.json'), AppScopes.deviceSettings);
    await _importSettings(
        File('$path/custom_colors.json'), AppScopes.customColors);
  }

  /// Imports an object of documents. The object is the file itself, unless
  /// [rootKey] points at a list of documents inside it.
  Future<void> _importObject(
    File file, {
    required String scope,
    String? rootKey,
  }) async {
    if (!file.existsSync()) return;

    final dynamic decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } catch (e) {
      print('[Asterfox] failed to import ${file.path}: $e');
      return;
    }

    // A history entry was stored inline, so its value keeps the entry's own
    // fields next to its id.
    final Map<String, String> entries;
    if (rootKey == null) {
      entries = {
        for (final entry in (decoded as Map).entries)
          entry.key as String: jsonEncode(entry.value)
      };
    } else {
      entries = {
        for (final entry in (decoded as Map)[rootKey] as List? ?? [])
          (entry as Map)["audioId"] as String: jsonEncode(entry)
      };
    }

    await _insertIfMissing(documents, entries, (key, json) =>
        DocumentsCompanion.insert(scope: scope, id: key, json: json));
  }

  /// Imports one of the single objects (`settings.json`, `device_settings.json`,
  /// `custom_colors.json`), whose entries become key-value rows.
  Future<void> _importSettings(File file, String scope) async {
    if (!file.existsSync()) return;

    final Map<String, dynamic> json;
    try {
      json =
          Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);
    } catch (e) {
      print('[Asterfox] failed to import ${file.path}: $e');
      return;
    }

    await _insertIfMissing(settingsEntries, json.map(
      (key, value) => MapEntry(key, jsonEncode(value)),
    ), (key, value) =>
        SettingsEntriesCompanion.insert(scope: scope, key: key, value: value));
  }

  /// Inserts [entries] into [table], skipping the rows that are stored already.
  Future<void> _insertIfMissing<T extends Table, D>(
    TableInfo<T, D> table,
    Map<String, String> entries,
    Insertable<D> Function(String key, String value) row,
  ) {
    return batch((batch) {
      for (final entry in entries.entries) {
        batch.insert(
          table,
          row(entry.key, entry.value),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}
