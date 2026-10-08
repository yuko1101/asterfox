import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import 'app_scopes.dart';
import 'database.dart';

class CustomColors {
  static final Map<String, int> defaultData = {"accent": Colors.orange.value};

  static const String _scope = AppScopes.customColors;
  static final Map<String, dynamic> _data = {};

  static AppDatabase get _db => AppDatabase.instance;

  static Future<void> init() async {
    await reloadDatabase();
    // Store the defaults of the colors that are still missing, so that every
    // stored color has a row.
    for (final entry in defaultData.entries) {
      if (!_data.containsKey(entry.key)) {
        await setValue(key: entry.key, value: entry.value);
      }
    }
  }

  /// Loads the stored colors into memory.
  static Future<void> reloadDatabase() async {
    final rows = await (_db.select(_db.settingsEntries)
          ..where((table) => table.scope.equals(_scope)))
        .get();
    _data
      ..clear()
      ..addAll({for (final row in rows) row.key: jsonDecode(row.value)});
  }

  /// Sets a color and stores it.
  static Future<void> setValue(
      {required String key, required int value}) async {
    _data[key] = value;
    await _db.settingsEntries.insertOnConflictUpdate(
      SettingsEntriesCompanion.insert(
        scope: _scope,
        key: key,
        value: jsonEncode(value),
      ),
    );
  }

  /// The color behind [name].
  static Color getColor(String name) {
    return Color(_data[name] as int);
  }
}
