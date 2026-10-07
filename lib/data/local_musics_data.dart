import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../music/downloader/downloader_manager.dart';
import '../music/music_data/music_data.dart';
import '../system/exceptions/local_song_not_found_exception.dart';
import '../system/exceptions/network_exception.dart';
import '../system/exceptions/song_not_stored_exception.dart';
import '../system/firebase/cloud_firestore.dart';
import '../utils/os.dart';
import '../utils/result.dart';
import 'app_scopes.dart';
import 'database.dart';

// TODO: add install system which enables you to download particular songs in music.json (https://github.com/yuko1101/asterfox/issues/29)
// TODO: move `remoteAudioUrl` into TemporaryData
class LocalMusicsData {
  static String get _scope => AppDatabase.userScopeOf(AppScopes.songs);

  /// The stored songs, keyed by audio id.
  static final Map<String, Map<String, dynamic>> _data = {};

  static AppDatabase get _db => AppDatabase.instance;

  static Future<void> init() async {
    await reloadDatabase();
  }

  /// Loads the stored songs into memory.
  static Future<void> reloadDatabase() async {
    final rows = await (_db.select(_db.documents)
          ..where((table) => table.scope.equals(_scope)))
        .get();
    _data
      ..clear()
      ..addAll({
        for (final row in rows)
          row.id: Map<String, dynamic>.from(jsonDecode(row.json) as Map)
      });
  }

  static bool isStored({MusicData? song, String? audioId}) {
    assert(song != null || audioId != null);
    return _data.containsKey(song?.audioId ?? audioId!);
  }

  static bool isInstalled({MusicData? song, String? audioId}) {
    assert(song != null || audioId != null);
    if (OS.isWeb) return false;
    final file = File(MusicData.getAudioInfoPath(song?.audioId ?? audioId!));
    return file.existsSync();
  }

  static Future<void> store(MusicData song) async {
    if (song.isStored) return;
    song.songStoredAt = DateTime.now().millisecondsSinceEpoch;
    await _save(song);
    await CloudFirestoreManager.addOrUpdateSongs([song]);
  }

  /// Stores the current state of an already stored song, for example after its
  /// lyrics or file size changed.
  static Future<void> save(MusicData song) async {
    if (!song.isStored) return;
    await _save(song);
  }

  /// Applies a song as received from the cloud. A null [json] removes it.
  static Future<void> applyRemoteChange(
      {required String audioId, Map<String, dynamic>? json}) async {
    if (json == null) {
      _data.remove(audioId);
      await _delete(audioId);
    } else {
      _data[audioId] = json;
      await _upsert(audioId, json);
    }
  }

  /// Replaces the stored songs, for example when importing an export.
  static Future<void> replaceAll(Map<String, dynamic> json) async {
    _data
      ..clear()
      ..addAll({
        for (final entry in json.entries)
          entry.key: Map<String, dynamic>.from(entry.value as Map)
      });
    await _db.transaction(() async {
      await (_db.delete(_db.documents)
            ..where((table) => table.scope.equals(_scope)))
          .go();
      for (final entry in _data.entries) {
        await _upsert(entry.key, entry.value);
      }
    });
  }

  /// The stored entries, in the shape the cloud stores them.
  static Map<String, dynamic> getStoredData() => _data;

  static Future<void> storeMultiple(List<MusicData> songs) async {
    for (final song in songs) {
      if (song.isStored) continue;
      song.songStoredAt = DateTime.now().millisecondsSinceEpoch;
      await _save(song);
    }
    await CloudFirestoreManager.addOrUpdateSongs(songs);
  }

  static Future<void> _save(MusicData song) async {
    final entry = song.toJson();
    _data[song.audioId] = entry;
    await _upsert(song.audioId, entry);
  }

  /// Throws [VideoUnplayableException], [NetworkException] and [SongNotStoredException].
  static Future<void> install(MusicData song) async {
    if (!song.isStored) throw SongNotStoredException();
    await DownloadManager.download(song);
  }

  /// Throws [VideoUnplayableException] and [NetworkException].
  static Future<void> download(MusicData song) async {
    await DownloadManager.download(song);
    // since song.size will be changed on download, store after download
    await store(song);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> uninstall(String audioId) async {
    if (!isStored(audioId: audioId)) throw SongNotStoredException();
    final dir = Directory(MusicData.getDirectoryPath(audioId));
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> uninstallSongs(List<String> audioIds) async {
    final futures = audioIds.map((id) => uninstall(id));
    await Future.wait(futures);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> delete(String audioId, {bool saveDataFile = true}) async {
    Future<void> deleteFromDataFile() async {
      _data.remove(audioId);
      if (saveDataFile) {
        await _delete(audioId);
        await CloudFirestoreManager.removeSongs([audioId]);
      }
    }

    await Future.wait([uninstall(audioId), deleteFromDataFile()]);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> deleteSongs(List<String> audioIds) async {
    final futures = audioIds.map((id) => delete(id, saveDataFile: false));
    await Future.wait(futures);
    await (_db.delete(_db.documents)
          ..where(
              (table) => table.scope.equals(_scope) & table.id.isIn(audioIds)))
        .go();
    await CloudFirestoreManager.removeSongs(audioIds);
  }

  static Future<void> _upsert(String audioId, Map<String, dynamic> entry) async {
    await _db.into(_db.documents).insert(
          DocumentsCompanion.insert(
            scope: _scope,
            id: audioId,
            json: jsonEncode(entry),
          ),
          onConflict: DoUpdate(
            (old) => DocumentsCompanion.insert(
              scope: _scope,
              id: audioId,
              json: jsonEncode(entry),
            ),
            target: [_db.documents.scope, _db.documents.id],
          ),
        );
  }

  static Future<void> _delete(String audioId) async {
    await (_db.delete(_db.documents)
          ..where((table) => table.scope.equals(_scope) & table.id.equals(audioId)))
        .go();
  }

  static List<MusicData<T>> getAll<T extends Caching>({required T caching}) {
    return _data.values
        .map((e) => MusicData.fromJson<T>(
              json: e,
              caching: caching.unique(),
            ))
        .toList();
  }

  // static List<String> getYouTubeIds() {
  //   final data = musicData.getValue(null) as Map<String, dynamic>;
  //   return data.values
  //       .where((element) => element["type"] == MusicType.youtube.name)
  //       .map((e) => e["id"] as String)
  //       .toList();
  // }

  static List<String> getStoredAudioIds() => _data.keys.toList();

  static MusicData<T> getByAudioId<T extends Caching>({
    required String audioId,
    required T caching,
  }) {
    final entry = _data[audioId];
    if (entry == null) throw LocalSongNotFoundException(audioId);
    return MusicData.fromJson(json: entry, caching: caching);
  }
}

extension LocalMusicsDataExtension on MusicData {
  Future<Result<void>> download() async {
    try {
      await LocalMusicsData.download(this);
      return Result.successful(null);
    } on Exception catch (e, stacktrace) {
      return Result.failed(
        ResultFailedReason(
          cause: e,
          title: e.toString(),
          description: stacktrace.toString(),
        ),
      );
    }
  }

  Future<void> store() async {
    await LocalMusicsData.store(this);
  }

  Future<Result<void>> install() async {
    try {
      await LocalMusicsData.install(this);
      return Result.successful(null);
    } on Exception catch (e, stacktrace) {
      return Result.failed(
        ResultFailedReason(
          cause: e,
          title: e.toString(),
          description: stacktrace.toString(),
        ),
      );
    }
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  Future<void> uninstall() async {
    await LocalMusicsData.uninstall(audioId);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  Future<void> delete() async {
    await LocalMusicsData.delete(audioId);
  }

  bool get isStored => LocalMusicsData.isStored(song: this);
  bool get isInstalled => LocalMusicsData.isInstalled(song: this);

  Future<String> get audioUrl async =>
      isInstalled ? audioSavePath : await getAvailableAudioUrl();

  String get cachedAudioUrl => isInstalled ? audioSavePath : remoteAudioUrl;

  String get imageUrl => isInstalled ? imageSavePath : remoteImageUrl;
}
