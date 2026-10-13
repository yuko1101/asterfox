import 'dart:io';

import 'package:asterfox/data/database.dart';
import 'package:asterfox/system/backup/backup_manager.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('the backup file that is returned is the one that was written', () async {
    final data = await Directory.systemTemp.createTemp('zipname_data');
    final temp = await Directory.systemTemp.createTemp('zipname_temp');
    addTearDown(() async {
      if (data.existsSync()) await data.delete(recursive: true);
      if (temp.existsSync()) await temp.delete(recursive: true);
    });

    final db =
        AppDatabase(NativeDatabase(File('${data.path}/asterfox.sqlite')));
    addTearDown(db.close);

    // The name is stamped from the clock. Moving it on between the stamp and
    // the return is what packing a real library does by itself when it takes
    // long enough to cross a second, so it is done explicitly here.
    var calls = 0;
    final manager = BackupManager(
      dataPath: data.path,
      tempPath: temp.path,
      database: db,
      now: () => DateTime(2026, 10, 13, 12, 0, calls++),
    );

    final backup = await manager.createBackup();

    expect(backup.existsSync(), isTrue,
        reason: 'the returned file does not exist: ${backup.path}');
    expect(backup.path, endsWith('asterfox-backup-20261013-120000.zip'));
    // The file name was stamped once, so it cannot drift from the file that
    // was written. (The clock is read a second time for the manifest, which
    // does not affect the name.)
    expect(calls, lessThanOrEqualTo(2));
  });
}
