import 'dart:convert';
import 'dart:io';

import 'package:asterfox/data/app_scopes.dart';
import 'package:asterfox/data/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the statements the data classes issue against a real database
/// file: scoped upserts, deletes and the legacy import running twice.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory directory;
  late AppDatabase db;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('asterfox_documents');
    db = AppDatabase(NativeDatabase(File('${directory.path}/test.sqlite')));
  });

  tearDown(() async {
    await db.close();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  /// The same upsert as `LocalMusicsData._upsert`.
  Future<void> upsert(String scope, String id, Map<String, dynamic> json) {
    return db.documents.insertOnConflictUpdate(
      DocumentsCompanion.insert(scope: scope, id: id, json: jsonEncode(json)),
    );
  }

  Future<List<Document>> documentsIn(String scope) async {
    final query = db.select(db.documents)
      ..where((table) => table.scope.equals(scope));
    return query.get();
  }

  test('an upsert replaces the row of the same scope and id', () async {
    final scope = '${AppScopes.local}/${AppScopes.songs}';
    await upsert(scope, 'songA', {'title': 'first'});
    await upsert(scope, 'songA', {'title': 'second'});

    final rows = await documentsIn(scope);
    expect(rows, hasLength(1));
    expect(rows.single.json, contains('second'));
  });

  test('the same id in another scope is a separate row', () async {
    // This is what signing in changes: the same audio id exists once per user.
    await upsert('${AppScopes.local}/${AppScopes.songs}', 'songA', {'a': 1});
    await upsert('user-1/${AppScopes.songs}', 'songA', {'a': 2});

    expect(await documentsIn('${AppScopes.local}/${AppScopes.songs}'),
        hasLength(1));
    expect(await documentsIn('user-1/${AppScopes.songs}'), hasLength(1));
  });

  test('a delete of one scope leaves the other scopes alone', () async {
    await upsert('${AppScopes.local}/${AppScopes.playlists}', 'p1', {'n': 1});
    await upsert('user-1/${AppScopes.playlists}', 'p1', {'n': 2});

    await (db.delete(db.documents)
          ..where((table) =>
              table.scope.equals('user-1/${AppScopes.playlists}') &
              table.id.equals('p1')))
        .go();

    expect(await documentsIn('${AppScopes.local}/${AppScopes.playlists}'),
        hasLength(1));
    expect(await documentsIn('user-1/${AppScopes.playlists}'), isEmpty);
  });

  test('history rows keep their insertion order', () async {
    final scope = '${AppScopes.local}/${AppScopes.history}';
    for (final id in ['songC', 'songA', 'songB']) {
      await upsert(scope, id, {'audioId': id});
    }

    final rows = await (db.select(db.documents)
          ..where((table) => table.scope.equals(scope))
          ..orderBy([(table) => OrderingTerm.asc(table.rowId)]))
        .get();
    expect(rows.map((row) => row.id), ['songC', 'songA', 'songB']);
  });

  test('a settings upsert keeps one row per key', () async {
    Future<void> put(String key, dynamic value) async {
      await db.settingsEntries.insertOnConflictUpdate(
        SettingsEntriesCompanion.insert(
          scope: AppScopes.settings,
          key: key,
          value: jsonEncode(value),
        ),
      );
    }

    await put('theme', 'dark');
    await put('theme', 'light');

    final rows = await (db.select(db.settingsEntries)
          ..where((table) => table.scope.equals(AppScopes.settings)))
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.value, '"light"');
  });

  test('a version 1 database keeps its colors after the schema upgrade',
      () async {
    // v1 stored the colors under "__custom_colors"; they now live under the
    // device scope, so opening the old file has to move the rows.
    final file = File('${directory.path}/upgrade.sqlite');
    final legacy = AppDatabase(NativeDatabase(file));
    await legacy.customStatement(
        "INSERT INTO settings_entries VALUES ('__custom_colors', 'accent', '17')");
    // Pretend the file was written before the scope was renamed.
    await legacy.customStatement('PRAGMA user_version = 1');
    await legacy.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);

    final rows = await (upgraded.select(upgraded.settingsEntries)
          ..where((table) => table.scope.equals(AppScopes.customColors)))
        .get();
    expect(rows.single.value, '17');
  });
}
