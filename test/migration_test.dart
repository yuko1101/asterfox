import 'dart:io';

import 'package:asterfox/data/app_scopes.dart';
import 'package:asterfox/data/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sample_data.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('asterfox_test');
    await createSampleData(directory.path);
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  /// Opens an in-memory database and imports the JSON files of [directory].
  Future<AppDatabase> openImported() async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.importLegacyJsonFiles(directory.path);
    return db;
  }

  Future<List<dynamic>> documentsOf(AppDatabase db, String scope) async {
    final rows = await (db.select(db.documents)
          ..where((table) => table.scope.equals(scope))
          ..orderBy([(table) => OrderingTerm.asc(table.id)]))
        .get();
    return rows.map((row) => row.json).toList();
  }

  test('imports songs from music.json', () async {
    final db = await openImported();
    final json = await documentsOf(
        db, '${AppScopes.local}/${AppScopes.songs}');

    expect(json.length, 2);
    expect(json.first, contains('"songA"'));
    expect(json.first, contains('"title":"Song A"'));
  });

  test('imports playlists without losing the song order', () async {
    final db = await openImported();
    final json = await documentsOf(
        db, '${AppScopes.local}/${AppScopes.playlists}');

    expect(json.length, 1);
    expect(json.first, contains('"name":"Favorites"'));
    expect(json.first, contains('"songs":["songA","songB"]'));
  });

  test('imports history entries with their own fields', () async {
    final db = await openImported();
    final json = await documentsOf(
        db, '${AppScopes.local}/${AppScopes.history}');

    expect(json.length, 2);
    expect(json.first, contains('"audioId":"songA"'));
    expect(json.first, contains('"lastPlayed":1'));
  });

  test('imports the single object settings', () async {
    final db = await openImported();

    Future<Map<String, String>> entriesOf(String scope) async {
      final rows = await (db.select(db.settingsEntries)
            ..where((table) => table.scope.equals(scope)))
          .get();
      return {for (final row in rows) row.key: row.value};
    }

    // settings.json
    final settings = await entriesOf(AppScopes.settings);
    expect(settings['theme'], '"light"');
    expect(settings['autoDownload'], 'true');
    // custom_colors.json used to be its own file, so it keeps its own scope.
    expect(settings.containsKey('accent'), isFalse);
    expect((await entriesOf(AppScopes.customColors))['accent'],
        '4278255615');

    // device_settings.json
    final deviceSettings =
        await entriesOf('${AppScopes.local}/${AppScopes.deviceSettings}');
    expect(deviceSettings['repeatMode'], '"all"');
    expect(deviceSettings['baseVolume'], '0.25');
  });

  test('imports the same file only once', () async {
    final db = await openImported();
    await db.importLegacyJsonFiles(directory.path);

    expect(
        await documentsOf(db, '${AppScopes.local}/${AppScopes.songs}'),
        hasLength(2));
  });
}
