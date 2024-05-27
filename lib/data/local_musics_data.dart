import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/music_downloader.dart';
import '../system/exceptions/local_song_not_found_exception.dart';
import '../system/exceptions/network_exception.dart';
import '../system/exceptions/song_not_stored_exception.dart';
import '../system/firebase/cloud_firestore.dart';
import '../utils/config_file.dart';
import '../utils/result.dart';

// TODO: add install system which enables you to download particular songs in music.json (https://github.com/yuko1101/asterfox/issues/29)
// TODO: move `remoteAudioUrl` into TemporaryData
class LocalMusicsData {
  static late ConfigFile localMusicData;

  static const bool compact = false;

  static Future<void> init() async {
    localMusicData = await ConfigFile(File("$localPath/music.json"), {}).load();
  }

  static bool isStored({MusicData? song, String? audioId}) {
    assert(song != null || audioId != null);
    return localMusicData.has(song?.audioId ?? audioId!);
  }

  static bool isInstalled({MusicData? song, String? audioId}) {
    assert(song != null || audioId != null);
    final file =
        File(MusicData.getInstallCompleteFilePath(song?.audioId ?? audioId!));
    return file.existsSync();
  }

  static Future<void> store(MusicData song) async {
    if (song.isStored) return;
    song.songStoredAt = DateTime.now().millisecondsSinceEpoch;
    await localMusicData
        .set(key: song.audioId, value: song.toJson())
        .save(compact: compact);
    await CloudFirestoreManager.addOrUpdateSongs([song]);
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
      localMusicData.delete(key: audioId);
      if (saveDataFile) {
        await localMusicData.save(compact: compact);
        await CloudFirestoreManager.removeSongs([audioId]);
      }
    }

    await Future.wait([uninstall(audioId), deleteFromDataFile()]);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> deleteSongs(List<String> audioIds) async {
    final futures = audioIds.map((id) => delete(id, saveDataFile: false));
    await Future.wait(futures);
    await localMusicData.save(compact: compact);
    await CloudFirestoreManager.removeSongs(audioIds);
  }

  static List<MusicData<T>> getAll<T extends Caching>({required T caching}) {
    final data = Map<String, dynamic>.from(localMusicData.getValue());
    return data.values
        .map((e) => MusicData.fromJson(
              json: e,
              key: const Uuid().v4(),
              caching: caching,
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

  static List<String> getStoredAudioIds() {
    final songs = localMusicData.getValue() as Map<String, dynamic>;
    return songs.keys.toList();
  }

  static MusicData<T> getByAudioId<T extends Caching>({
    required String audioId,
    required String key,
    required T caching,
  }) {
    if (!localMusicData.has(audioId)) throw LocalSongNotFoundException(audioId);
    final data = localMusicData.getValue(audioId) as Map<String, dynamic>;
    return MusicData.fromJson(json: data, key: key, caching: caching);
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
