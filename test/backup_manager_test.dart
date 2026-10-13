import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:asterfox/data/database.dart';
import 'package:asterfox/system/backup/backup_manager.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory data;
  late Directory temp;

  setUp(() async {
    data = await Directory.systemTemp.createTemp('asterfox_backup_data');
    temp = await Directory.systemTemp.createTemp('asterfox_backup_temp');
    await Directory('${data.path}/music/songA').create(recursive: true);
    await File('${data.path}/music/songA/audio').writeAsBytes([1, 2, 3]);
    await File('${data.path}/music/songA/info.json').writeAsString('{}');
  });

  tearDown(() async {
    if (data.existsSync()) await data.delete(recursive: true);
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  /// Opens the database the manager works against and fills it with one row.
  Future<AppDatabase> openDatabase() async {
    final db =
        AppDatabase(NativeDatabase(File('${data.path}/asterfox.sqlite')));
    await db.customStatement(
      "INSERT INTO documents (scope, id, json) VALUES ('local/songs', 'songA', '{\"title\":\"A\"}')",
    );
    return db;
  }

  /// Reads the song rows of the database file at [path], opening it directly.
  Future<List<String>> songsOf(String path) async {
    final db = AppDatabase(NativeDatabase(File(path)));
    final rows = await (db.select(db.documents)
          ..where((table) => table.scope.equals('local/songs'))
          ..orderBy([(table) => OrderingTerm.asc(table.id)]))
        .get();
    await db.close();
    return rows.map((row) => row.json).toList();
  }

  /// Builds a zip of the given text entries, to stand in for a bad backup.
  File writeZip(String name, Map<String, String> entries) {
    final archive = Archive();
    for (final entry in entries.entries) {
      archive.add(ArchiveFile.string(entry.key, entry.value));
    }
    final file = File('${temp.path}/$name');
    file.writeAsBytesSync(ZipEncoder().encode(archive));
    return file;
  }

  test('a backup holds the database and the stored music', () async {
    final db = await openDatabase();
    final manager =
        BackupManager(dataPath: data.path, tempPath: temp.path, database: db);

    final backup = await manager.createBackup();
    expect(backup.existsSync(), isTrue);

    // The rows that were still only in the WAL are in the snapshot.
    final snapshot = File('${temp.path}/copy.sqlite');
    final archive = ZipDecoder().decodeBytes(backup.readAsBytesSync());
    snapshot.writeAsBytesSync(
        archive.findFile('asterfox.sqlite')!.content as List<int>);
    expect(await songsOf(snapshot.path), ['{"title":"A"}']);
    snapshot.deleteSync();

    await db.close();
  });

  test('restoring replaces the database and the music folder', () async {
    final db = await openDatabase();
    final manager =
        BackupManager(dataPath: data.path, tempPath: temp.path, database: db);
    final backup = await manager.createBackup();
    await db.close();

    // Diverge from the backup: another row, and another song on disk.
    final changed = AppDatabase(NativeDatabase(File(manager.databasePath)));
    await changed.customStatement(
      "INSERT INTO documents (scope, id, json) VALUES ('local/songs', 'songB', '{\"title\":\"B\"}')",
    );
    await changed.close();
    await File('${data.path}/music/songB/audio')
        .create(recursive: true)
        .then((file) => file.writeAsBytes([9]));

    await manager.restoreBackup(backup);

    // The row added after the backup is gone, and the music folder is the one
    // of the backup.
    expect(await songsOf(manager.databasePath), ['{"title":"A"}']);
    expect(Directory('${data.path}/music/songB').existsSync(), isFalse);
    expect(
      File('${data.path}/music/songA/audio').readAsBytesSync(),
      [1, 2, 3],
    );
    // The temporary folders the manager works in are cleaned up.
    expect(Directory('${data.path}/.restore').existsSync(), isFalse);
    expect(File('${temp.path}/asterfox.sqlite').existsSync(), isFalse);
  });

  test('a file that is not a backup is refused and changes nothing', () async {
    final db = await openDatabase();
    final manager = BackupManager(dataPath: data.path, tempPath: temp.path);

    final bogus = writeZip('not-a-backup.zip', {'other.txt': 'hello'});

    await expectLater(
      manager.restoreBackup(bogus),
      throwsA(isA<BackupException>()),
    );
    // The database that was there is untouched.
    expect(await songsOf(manager.databasePath), ['{"title":"A"}']);

    await db.close();
  });

  test('a backup written by a newer format is refused', () async {
    final db = await openDatabase();
    final manager =
        BackupManager(dataPath: data.path, tempPath: temp.path, database: db);
    await db.close();

    final newer = writeZip('newer.zip', {
      BackupManager.manifestName: jsonEncode({
        "app": "asterfox",
        "format": BackupManager.formatVersion + 1,
        "databaseVersion": 999,
      }),
    });

    await expectLater(
      manager.restoreBackup(newer),
      throwsA(isA<BackupException>()),
    );
  });

  test('a backup without the database is refused and changes nothing',
      () async {
    final db = await openDatabase();
    final manager =
        BackupManager(dataPath: data.path, tempPath: temp.path, database: db);

    // A well formed manifest, but the database it promises is missing.
    final empty = writeZip('no-database.zip', {
      BackupManager.manifestName: jsonEncode({
        "app": "asterfox",
        "format": BackupManager.formatVersion,
        "databaseVersion": 2,
      }),
    });

    await expectLater(
      manager.restoreBackup(empty),
      throwsA(isA<BackupException>()),
    );
    expect(await songsOf(manager.databasePath), ['{"title":"A"}']);
    expect(Directory('${data.path}/music/songA').existsSync(), isTrue);

    await db.close();
  });
}
