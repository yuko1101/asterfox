import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

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
  ///
  /// The zip holds the whole music library, so it is never held in memory:
  /// every step works with the file on disk.
  Future<String?> exportToFile() async {
    final backup = await manager.createBackup();
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // The mobile save dialog does not hand back a usable path (the target
        // is a content uri) and takes the file as bytes, which a large backup
        // cannot be. The share sheet streams the file instead, and doubles as
        // the way to put it in storage or send it elsewhere.
        await SharePlus.instance.share(ShareParams(
          files: [XFile(backup.path)],
          fileNameOverrides: [p.basename(backup.path)],
        ));
        return backup.path;
      }

      final picked = await _openDialog(() => FilePicker.platform.saveFile(
            dialogTitle: "Save backup",
            fileName: p.basename(backup.path),
            type: FileType.any,
          ));
      if (picked == null) return null;
      final target = File(picked);
      if (target.absolute.path != backup.absolute.path) {
        // Copied in chunks, not loaded whole.
        await backup.openRead().pipe(target.openWrite());
      }
      return picked;
    } finally {
      if (backup.existsSync()) backup.deleteSync();
    }
  }

  /// Asks for a backup file and restores it, returning whether one was
  /// restored. Throws [BackupException] when the file cannot be used.
  Future<bool> importFromFile() async {
    // `withData` is left off so the chosen zip is not read into memory. On
    // mobile the plugin caches a picked uri to a file of its own and returns
    // that path.
    final result = await _openDialog(() => FilePicker.platform.pickFiles(
          dialogTitle: "Open backup",
          type: FileType.any,
        ));
    if (result == null || result.files.isEmpty) return false;
    final picked = result.files.first;

    // A picked file is never modified, so its path is used as it is.
    final path = picked.path;
    if (path == null) {
      throw BackupException("Could not read the selected file");
    }
    await manager.restoreBackup(File(path));
    return true;
  }
}
