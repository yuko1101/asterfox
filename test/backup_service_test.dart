import 'dart:async';
import 'dart:io';

import 'package:asterfox/data/database.dart';
import 'package:asterfox/system/backup/backup_manager.dart';
import 'package:asterfox/system/backup/backup_service.dart';
// `isNull` is the matcher here, not the query builder helper of drift.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the system file dialogs, which cannot open in a test.
class FakeFilePicker extends FilePicker {
  FakeFilePicker({
    this.savePath,
    this.openFile,
    this.throwOnSave = false,
    this.hang = false,
  });

  /// What the save dialog returns; null means the user cancelled.
  final String? savePath;

  /// What the open dialog returns.
  final PlatformFile? openFile;

  /// Whether the save dialog fails, as it does with no file manager.
  final bool throwOnSave;

  /// Whether the dialog never answers, as it does with no dialog service.
  final bool hang;

  Uint8List? savedBytes;
  bool exported = false;

  /// A future that never completes, to stand in for a dialog that hangs.
  Future<T> _never<T>() => Completer<T>().future;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    if (hang) return _never();
    if (throwOnSave) throw Exception('no file manager');
    exported = true;
    savedBytes = bytes;
    return savePath;
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    int compressionQuality = 0,
  }) async {
    if (hang) return _never();
    if (openFile == null) return null;
    return FilePickerResult([openFile!]);
  }
}

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
    manager = BackupManager(dataPath: data.path, tempPath: temp.path, database: db);
  });

  tearDown(() async {
    await db.close();
    if (data.existsSync()) await data.delete(recursive: true);
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  BackupService service() => BackupService(manager: manager);

  test('export writes the backup where the dialog says', () async {
    final target = '${temp.path}/chosen/asterfox.zip';
    await Directory('${temp.path}/chosen').create(recursive: true);
    final picker = FakeFilePicker(savePath: target);
    FilePicker.platform = picker;

    final path = await service().exportToFile();

    expect(path, target);
    expect(File(target).existsSync(), isTrue);
    // The file the dialog was handed is a real zip, and the copy left in the
    // temporary folder is cleaned up.
    expect(File(target).lengthSync(), greaterThan(0));
    expect(Directory(temp.path).listSync().whereType<File>(), isEmpty);
  });

  test('export reports a cancelled dialog and leaves nothing behind',
      () async {
    final picker = FakeFilePicker();
    FilePicker.platform = picker;

    expect(await service().exportToFile(), isNull);
    expect(Directory(temp.path).listSync().whereType<File>(), isEmpty);
  });

  test('a failing save dialog is reported, not swallowed', () async {
    FilePicker.platform = FakeFilePicker(savePath: '/tmp/x.zip', throwOnSave: true);

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
        openFile: PlatformFile(
            name: 'picked.zip', path: chosen.path, size: 0));

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
