import 'dart:convert';

import 'package:drift/drift.dart';

import '../main.dart';
import '../widget/music_widgets/repeat_button.dart';
import 'app_scopes.dart';
import 'database.dart';

class DeviceSettingsData {
  static const Map<String, dynamic> defaultData = {
    "repeatMode": "none",
    "baseVolume": 1.0,
  };

  static const String _scope =
      '${AppScopes.local}/${AppScopes.deviceSettings}';

  static final Map<String, dynamic> _data = {};

  /// The stored device settings.
  static Map<String, dynamic> get data => _data;

  static AppDatabase get _db => AppDatabase.instance;

  static Future<void> init() async {
    await reloadDatabase();
    // Store the defaults that have not been saved yet, like the config file
    // used to be created with them.
    for (final entry in defaultData.entries) {
      if (!_data.containsKey(entry.key)) {
        await setValue(key: entry.key, value: entry.value);
      }
    }
  }

  /// Loads the stored device settings into memory.
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

  static Future<void> apply() async {}

  static dynamic getValue({String? key, List<String>? keys}) {
    if (key == null && keys == null) return _data;
    if (key != null) return _data[key] ?? defaultData[key];
    if (keys != null) {
      var map = _data;
      for (var key in keys) {
        map = map[key] ?? defaultData[key];
      }
      return map;
    }
  }

  static bool _initializedRepeatListener = false;
  static Future<void> applyMusicManagerSettings() async {
    if (!_initializedRepeatListener) {
      musicManager.audioStateManager.repeatStateNotifier.addListener(() {
        setValue(
          key: "repeatMode",
          value: repeatStateToString(musicManager.state.repeatState),
        );
      });
      _initializedRepeatListener = true;
    }
    if (repeatStateToString(musicManager
            .audioStateManager.repeatStateNotifier.value.repeatState) !=
        getValue(key: "repeatMode") as String) {
      musicManager.setRepeatMode(
          repeatStateFromString(getValue(key: "repeatMode") as String));
    }

    await musicManager.setBaseVolume(getValue(key: "baseVolume") as double);
  }
}
