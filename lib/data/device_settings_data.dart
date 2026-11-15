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

  static const String _scope = AppScopes.deviceSettings;

  static final Map<String, dynamic> _data = {};

  /// The stored device settings.
  static Map<String, dynamic> get data => _data;

  static AppDatabase get _db => AppDatabase.instance;

  static Future<void> init() async {
    await reloadDatabase();
    // Store the defaults of the keys that are still missing, so that every
    // stored setting has a row.
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
    await _db.settingsEntries.insertOnConflictUpdate(
      SettingsEntriesCompanion.insert(
        scope: _scope,
        key: key,
        value: jsonEncode(value),
      ),
    );
  }

  /// The value of [key], or its default when it is not stored.
  static dynamic getValue({required String key}) =>
      _data[key] ?? defaultData[key];

  static bool _initializedRepeatListener = false;
  static Future<void> applyMusicManagerSettings() async {
    // The stored mode is applied before the changes are listened to, so that
    // the mode the player starts with is not stored over it.
    final repeatMode = getValue(key: "repeatMode") as String;
    if (repeatStateToString(musicManager.state.repeatState) != repeatMode) {
      await musicManager.setRepeatMode(repeatStateFromString(repeatMode));
    }
    if (!_initializedRepeatListener) {
      musicManager.audioStateManager.repeatStateNotifier.addListener(() {
        setValue(
          key: "repeatMode",
          value: repeatStateToString(musicManager.state.repeatState),
        );
      });
      _initializedRepeatListener = true;
    }

    await musicManager
        .setBaseVolume((getValue(key: "baseVolume") as num).toDouble());
  }
}
