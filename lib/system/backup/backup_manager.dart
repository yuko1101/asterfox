import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';

import '../../data/database.dart';

/// Thrown when a file is not a backup this app can restore.
class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exports and imports the data this app keeps on the device: the SQLite
/// database and the folder holding the stored music (the audio, image and
/// info.json of each song), as a single zip file.
///
/// The cloud sync in `system/firebase/cloud_firestore.dart` carries only the
/// rows of the signed in user. This is the whole-device backup and is
/// independent of it: it also holds the scopes that never leave the device
/// (history, device settings, custom colors) and the music files themselves.
class BackupManager {
  BackupManager({
    required this.dataPath,
    required this.tempPath,
    AppDatabase? database,
    DateTime Function()? now,
  })  : _database = database,
        _now = now ?? DateTime.now;

  /// The folder the database and `music/` are stored in (`localPath` of
  /// main.dart).
  final String dataPath;

  /// A folder to write the snapshot and the extracted files to (`tempPath`).
  final String tempPath;

  /// The database to export. Defaults to the one the app opened.
  final AppDatabase? _database;

  /// The clock the backup file name is stamped with.
  final DateTime Function() _now;

  AppDatabase get _db => _database ?? AppDatabase.instance;

  /// The version of the layout of the zip. A backup written by a newer app is
  /// refused rather than half-restored.
  static const int formatVersion = 1;

  static const String manifestName = "asterfox-backup.json";
  static const String _databaseName = "asterfox.sqlite";
  static const String _musicDirName = "music";

  /// A database in WAL mode keeps its recent writes in these files.
  static const List<String> _databaseSideFiles = ["-wal", "-shm"];

  String get databasePath => "$dataPath/$_databaseName";
  String get musicPath => "$dataPath/$_musicDirName";

  /// The names the parts of a backup are stored under.
  String get _snapshotPath => "$tempPath/$_databaseName";
  String get _extractPath => "$dataPath/.restore";

  /// A name for a new backup file, e.g. `asterfox-backup-20261013-120000.zip`.
  String suggestedFileName() {
    final now = _now();
    String two(int value) => value.toString().padLeft(2, "0");
    final stamp = "${now.year}${two(now.month)}${two(now.day)}"
        "-${two(now.hour)}${two(now.minute)}${two(now.second)}";
    return "asterfox-backup-$stamp.zip";
  }

  /// Writes a backup of the current data and returns the file it wrote.
  ///
  /// The caller owns the returned file and may move or delete it.
  Future<File> createBackup() async {
    final directory = Directory(tempPath);
    if (!directory.existsSync()) directory.createSync(recursive: true);

    // Stamp the name once: packing the music of a real device takes long
    // enough that a second call would land on a different second and name a
    // file that was never written.
    final zip = File("$tempPath/${suggestedFileName()}");

    final snapshot = File(_snapshotPath);
    if (snapshot.existsSync()) snapshot.deleteSync();

    // VACUUM INTO writes the snapshot through the connection that owns the
    // database, so it sees the rows that are still only in the WAL. Copying
    // the file itself would miss them.
    await _db.customStatement("VACUUM INTO ?", [_snapshotPath]);

    final music = Directory(musicPath);

    final encoder = ZipFileEncoder();
    encoder.create(zip.path);
    try {
      await encoder.addFile(snapshot, _databaseName);
      if (music.existsSync()) {
        await encoder.addDirectory(music, includeDirName: true);
      }
      encoder.addArchiveFile(ArchiveFile.string(
        manifestName,
        jsonEncode({
          "app": "asterfox",
          "format": formatVersion,
          "createdAt": _now().toIso8601String(),
          "databaseVersion": _db.schemaVersion,
          "includesMusic": music.existsSync(),
        }),
      ));
      await encoder.close();
    } catch (e) {
      // An encoder that was started but not closed holds the file open.
      await encoder.close();
      rethrow;
    } finally {
      if (snapshot.existsSync()) snapshot.deleteSync();
    }

    return zip;
  }

  /// Replaces the stored data with the contents of [backup].
  ///
  /// The database file is swapped underneath the running app, so the imported
  /// data becomes visible after the app is restarted, not before.
  ///
  /// Throws [BackupException] if [backup] is not a backup this app can restore.
  /// Nothing is replaced in that case.
  Future<void> restoreBackup(File backup) async {
    final extract = Directory(_extractPath);
    if (extract.existsSync()) extract.deleteSync(recursive: true);
    extract.createSync(recursive: true);

    try {
      // Entries whose path would land outside the folder are skipped, so a
      // crafted zip cannot write over other files.
      await extractFileToDisk(backup.path, extract.path);

      final manifest = _readManifest(extract);
      final database = File("${extract.path}/$_databaseName");
      if (!database.existsSync()) {
        throw BackupException(
            "The backup does not contain $manifestName's $_databaseName");
      }
      final version = manifest["databaseVersion"] as int?;
      if (version != null && version > _db.schemaVersion) {
        throw BackupException(
            "The backup was written by a newer version of the app "
            "(database $version > ${_db.schemaVersion})");
      }

      final music = Directory("${extract.path}/$_musicDirName");
      _replaceDirectory(music, Directory(musicPath));

      for (final suffix in _databaseSideFiles) {
        final sideFile = File("$databasePath$suffix");
        if (sideFile.existsSync()) sideFile.deleteSync();
      }
      final target = File(databasePath);
      if (target.existsSync()) target.deleteSync();
      // The extract folder is inside dataPath, so this rename stays on one
      // filesystem.
      database.renameSync(databasePath);
    } finally {
      if (extract.existsSync()) extract.deleteSync(recursive: true);
    }
  }

  /// Reads the manifest of an extracted backup and checks it is one of ours.
  ///
  /// Throws [BackupException] when it is not.
  Map<String, dynamic> _readManifest(Directory extract) {
    final file = File("${extract.path}/$manifestName");
    if (!file.existsSync()) {
      throw BackupException("Not an Asterfox backup: $manifestName is missing");
    }
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map || json["app"] != "asterfox") {
      throw BackupException("Not an Asterfox backup");
    }
    final format = json["format"] as int?;
    if (format == null || format > formatVersion) {
      throw BackupException("The backup needs a newer version of the app");
    }
    return Map<String, dynamic>.from(json);
  }

  /// Puts [source] in place of [target], both inside [dataPath]. A backup
  /// replaces the stored music as a whole, so a song that is not in the backup
  /// is gone afterwards.
  void _replaceDirectory(Directory source, Directory target) {
    if (!source.existsSync()) return;
    if (target.existsSync()) target.deleteSync(recursive: true);
    source.renameSync(target.path);
  }
}
