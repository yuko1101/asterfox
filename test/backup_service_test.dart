import 'dart:io';
import 'dart:math';

import 'package:asterfox/data/database.dart';
import 'package:asterfox/system/backup/backup_manager.dart';
import 'package:asterfox/system/backup/backup_service.dart';
// `isNull` is the matcher here, not the query builder helper of drift.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_file_picker.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory data;
  late Directory temp;
  late AppDatabase db;
  late BackupManager manager;

  setUp(() async {
    data = await Directory.systemTemp.createTemp('asterfox_service_data');
    temp = await Directory.systemTemp.createTemp('asterfox_service_temp');
    await Directory('${data.path}/music/songA').create(recursive: true);
    await File('${data.path}/music/songA/audio').writeAsBytes([1, 2, 3]);
    db = AppDatabase(NativeDatabase(File('${data.path}/asterfox.sqlite')));
    await db.customStatement(
      "INSERT INTO documents (scope, id, json) VALUES ('local/songs', 'songA', '{\"title\":\"A\"}')",
    );
    manager =
        BackupManager(dataPath: data.path, tempPath: temp.path, database: db);
  });

  tearDown(() async {
    await db.close();
    if (data.existsSync()) await data.delete(recursive: true);
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  BackupService service() => BackupService(manager: manager);

  /// Fills the library with [count] songs of [bytes] of incompressible data
  /// each, so a backup is genuinely large rather than a deflate of zeros.
  Future<void> storeSongs(int count, int bytes) async {
    final random = Random(7);
    for (var song = 0; song < count; song++) {
      final dir = Directory('${data.path}/music/song$song');
      await dir.create(recursive: true);
      final audio = List<int>.generate(bytes, (_) => random.nextInt(256));
      await File('${dir.path}/audio').writeAsBytes(audio);
    }
  }

  test('export writes the backup where the dialog says', () async {
    final target = '${temp.path}/chosen/asterfox.zip';
    await Directory('${temp.path}/chosen').create(recursive: true);
    final picker = FakeFilePicker(savePath: target);
    FilePicker.platform = picker;

    final path = await service().exportToFile();

    expect(path, target);
    expect(File(target).existsSync(), isTrue);
    expect(File(target).lengthSync(), greaterThan(0));
    // The zip went to the dialog as a path, not as bytes: loading it whole is
    // what runs a large library out of memory.
    expect(picker.savedBytes, isNull);
    // The copy left in the temporary folder is cleaned up.
    expect(Directory(temp.path).listSync().whereType<File>(), isEmpty);
  });

  test('a backup larger than memory can be exported', () async {
    // 48 MB of music: the point is that the export never holds the zip in
    // memory, so its size does not matter.
    await storeSongs(24, 2 * 1024 * 1024);
    final target = '${temp.path}/big.zip';
    final picker = FakeFilePicker(savePath: target);
    FilePicker.platform = picker;

    final path = await service().exportToFile();

    expect(path, target);
    expect(File(target).lengthSync(), greaterThan(40 * 1024 * 1024));
    expect(picker.savedBytes, isNull);
  });

  test('export reports a cancelled dialog and leaves nothing behind',
      () async {
    final picker = FakeFilePicker();
    FilePicker.platform = picker;

    expect(await service().exportToFile(), isNull);
    expect(Directory(temp.path).listSync().whereType<File>(), isEmpty);
  });

  test('export reports progress over the whole range', () async {
    await storeSongs(6, 64 * 1024);
    FilePicker.platform = FakeFilePicker(savePath: '${temp.path}/p.zip');

    final seen = <int>[];
    await service().exportToFile(onProgress: seen.add);

    expect(seen, isNotEmpty);
    // It starts at nothing done and ends at everything done.
    expect(seen.first, 0);
    expect(seen.last, 100);
    // Progress only ever moves forward, so the bar cannot jump backwards.
    expect(seen, orderedEquals(List<int>.from(seen)..sort()));
    expect(seen.every((percent) => percent >= 0 && percent <= 100), isTrue);
    // The songs are the slow part, so the range covers them rather than
    // sitting at 0 until they are done.
    expect(seen.where((percent) => percent > 0 && percent < 100), isNotEmpty);
  });

  test('a failing save dialog is reported, not swallowed', () async {
    FilePicker.platform =
        FakeFilePicker(savePath: '/tmp/x.zip', throwOnSave: true);

    await expectLater(service().exportToFile(), throwsA(isA<Exception>()));
    // The backup written before the dialog failed is cleaned up.
    expect(Directory(temp.path).listSync().whereType<File>(), isEmpty);
  });

  test('import restores the file the dialog returns', () async {
    // Write a backup holding one song, then change the data on disk.
    final backup = await manager.createBackup();
    final chosen = File('${temp.path}/picked.zip');
    backup.copySync(chosen.path);
    backup.deleteSync();
    await db.customStatement(
      "INSERT INTO documents (scope, id, json) VALUES ('local/songs', 'songB', '{\"title\":\"B\"}')",
    );

    FilePicker.platform = FakeFilePicker(
        openFile:
            PlatformFile(name: 'picked.zip', path: chosen.path, size: 0));

    expect(await service().importFromFile(), isTrue);

    final restored = AppDatabase(NativeDatabase(File(manager.databasePath)));
    final rows = await restored.select(restored.documents).get();
    await restored.close();
    expect(rows.map((row) => row.id), ['songA']);
    // A picked file is left where it was.
    expect(chosen.existsSync(), isTrue);
  });

  test('import reports when the user cancels', () async {
    FilePicker.platform = FakeFilePicker();

    expect(await service().importFromFile(), isFalse);
  });

  test('a dialog that never answers fails instead of hanging the app',
      () async {
    // The real timeout is minutes long; it is shortened here to keep the test
    // quick. What is checked is that the call gives up instead of waiting.
    FilePicker.platform = FakeFilePicker(hang: true);
    final hanging = BackupService(
      manager: manager,
      dialogTimeout: const Duration(milliseconds: 300),
    );
    final watch = Stopwatch()..start();

    await expectLater(hanging.exportToFile(), throwsA(isA<BackupException>()));
    expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
    // The backup written before the dialog hung is cleaned up.
    expect(Directory(temp.path).listSync().whereType<File>(), isEmpty);
  });
}
