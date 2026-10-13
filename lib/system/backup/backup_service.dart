import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../main.dart';
import 'backup_manager.dart';

/// Lets the user write a backup somewhere and pick one to restore, using the
/// system file dialogs.
class BackupService {
  BackupService({
    BackupManager? manager,
    this.dialogTimeout = defaultDialogTimeout,
  }) : manager = manager ??
            BackupManager(dataPath: localPath, tempPath: tempPath);

  final BackupManager manager;

  /// How long to wait for a file dialog before giving up on it.
  ///
  /// On a desktop with no file dialog service the call waits forever instead
  /// of failing, which would leave the app on a progress dialog with no way
  /// out. This is a guard against that, not a limit on the user: it is long
  /// enough to browse for a file.
  static const Duration defaultDialogTimeout = Duration(minutes: 5);

  final Duration dialogTimeout;

  /// Runs [dialog] and returns what it answered, or throws [BackupException]
  /// when it never answered.
  Future<T?> _openDialog<T>(Future<T?> Function() dialog) async {
    try {
      return await dialog().timeout(dialogTimeout);
    } on TimeoutException {
      throw BackupException(
          "The file dialog did not respond. Is a file manager available?");
    }
  }

  /// Asks where to write a backup, writes it and returns the path, or null
  /// when the user cancelled or the dialog did not answer.
  Future<String?> exportToFile() async {
    final backup = await manager.createBackup();
    try {
      // Android and iOS are handed the bytes and write the file themselves,
      // because the picked location is not a plain file path there.
      final picksContents = Platform.isAndroid || Platform.isIOS;
      final picked = await _openDialog(() => FilePicker.platform.saveFile(
            dialogTitle: "Save backup",
            fileName: p.basename(backup.path),
            type: FileType.any,
            bytes: picksContents ? backup.readAsBytesSync() : null,
          ));
      if (picked == null) return null;
      if (!picksContents) {
        final target = File(picked);
        if (target.absolute.path != backup.absolute.path) {
          target.writeAsBytesSync(backup.readAsBytesSync());
        }
      }
      return picked;
    } finally {
      if (backup.existsSync()) backup.deleteSync();
    }
  }

  /// Asks for a backup file and restores it, returning whether one was
  /// restored. Throws [BackupException] when the file cannot be used.
  Future<bool> importFromFile() async {
    final result = await _openDialog(() => FilePicker.platform.pickFiles(
          dialogTitle: "Open backup",
          type: FileType.any,
          // A file picked on Android or iOS can be a content:// uri, which the
          // plugin hands over as contents instead of a path.
          withData: Platform.isAndroid || Platform.isIOS,
        ));
    if (result == null || result.files.isEmpty) return false;
    final picked = result.files.first;

    // A picked file is never modified, so a path is used as it is.
    final File file;
    if (picked.path != null) {
      file = File(picked.path!);
    } else if (picked.bytes != null) {
      file = File("$tempPath/backup-import.zip")
        ..writeAsBytesSync(picked.bytes!);
    } else {
      // Neither a path nor the contents were handed over, so there is nothing
      // to read.
      throw BackupException("Could not read the selected file");
    }
    try {
      await manager.restoreBackup(file);
      return true;
    } finally {
      if (picked.path == null && file.existsSync()) file.deleteSync();
    }
  }
}