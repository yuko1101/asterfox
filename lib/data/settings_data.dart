import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../system/firebase/cloud_firestore.dart';
import '../system/theme/theme.dart';
import 'app_scopes.dart';
import 'database.dart';

class SettingsData {
  static const Map<String, dynamic> defaultData = {
    "theme": "dark",
    "autoDownload": false,
    "disableInterruptions": false,
    "audioChannel": "media",
  };

  static const String _scope = AppScopes.settings;

  static final Map<String, dynamic> _data = {};

  /// The stored settings.
  static Map<String, dynamic> get data => _data;

  static AppDatabase get _db => AppDatabase.instance;

  static Future<void> init() async {
    await reloadDatabase();
    // Store the defaults that have not been stored yet, like the config file
    // used to be created with them.
    for (final entry in defaultData.entries) {
      if (!_data.containsKey(entry.key)) {
        await setValue(key: entry.key, value: entry.value);
      }
    }
  }

  /// Loads the stored settings into memory.
  static Future<void> reloadDatabase() async {
    final rows = await (_db.select(_db.settingsEntries)
          ..where((table) => table.scope.equals(_scope)))
        .get();
    _data
      ..clear()
      ..addAll({for (final row in rows) row.key: jsonDecode(row.value)});
  }

  /// Sets a value and stores it.
  static Future<void> setValue(
      {required String key, required dynamic value}) async {
    _data[key] = value;
    await _db.into(_db.settingsEntries).insert(
          SettingsEntriesCompanion.insert(
            scope: _scope,
            key: key,
            value: jsonEncode(value),
          ),
          onConflict: DoUpdate(
            (_) => SettingsEntriesCompanion.insert(
              scope: _scope,
              key: key,
              value: jsonEncode(value),
            ),
            target: [_db.settingsEntries.scope, _db.settingsEntries.key],
          ),
        );
  }

  /// Removes the stored values and puts the defaults back, like the config
  /// file it replaces did.
  static Future<void> resetData() async {
    _data
      ..clear()
      ..addAll(defaultData);
    await (_db.delete(_db.settingsEntries)
          ..where((table) => table.scope.equals(_scope)))
        .go();
    for (final entry in defaultData.entries) {
      await setValue(key: entry.key, value: entry.value);
    }
  }

  /// Merges the given settings into the stored ones. The entries that are not
  /// app settings (device settings, custom colors) are left untouched.
  static Future<void> applyRemoteData(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      if (!defaultData.containsKey(entry.key)) continue;
      await setValue(key: entry.key, value: entry.value);
    }
  }

  static Future<void> save({bool upload = true}) async {
    if (shouldInitializeFirebase &&
        FirebaseAuth.instance.currentUser != null &&
        upload) {
      await CloudFirestoreManager.updateUserData();
    }
  }

  static Future<void> applySettings() async {
    if (AppTheme.themeNotifier.value.themeDetails.name !=
        getValue(key: "theme") as String) {
      AppTheme.themeNotifier.value =
          AppTheme.getTheme(getValue(key: "theme") as String);
    }
  }

  static dynamic getValue({String? key, List<String>? keys}) {
    if (key == null && keys == null) return _data;
    if (key != null) return _data[key] ?? defaultData[key];
    if (keys != null) {
      var data = _data;
      for (var key in keys) {
        data = data[key] ?? defaultData[key];
      }
      return data;
    }
  }
}
