import 'dart:io';

import 'package:asterfox/system/exceptions/song_not_stored_exception.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/music_downloader.dart';
import '../system/exceptions/local_song_not_found_exception.dart';
import '../system/exceptions/network_exception.dart';
import '../system/firebase/cloud_firestore.dart';

// TODO: add install system which enables you to download particular songs in music.json (https://github.com/yuko1101/asterfox/issues/29)
// TODO: move `remoteAudioUrl` into TemporaryData
class LocalMusicsData {
  static late ConfigFile musicData;

  static const bool compact = false;

  static Future<void> init() async {
    musicData =
        await ConfigFile(File("${EasyApp.localPath}/music.json"), {}).load();
  }

  static bool isStored({MusicData? song, String? audioId}) {
    assert(song != null || audioId != null);
    return musicData.has(song?.audioId ?? audioId!);
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
    await musicData
        .set(key: song.audioId, value: song.toJson())
        .save(compact: compact);
    await CloudFirestoreManager.addOrUpdateSongs([song]);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> install(MusicData song) async {
    if (!song.isStored) throw SongNotStoredException();
    await MusicDownloader.download(song);
  }

  static Future<void> download(MusicData song) async {
    await MusicDownloader.download(song);
    // since song.size will be changed on download, store after download
    await store(song);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> uninstall(String audioId) async {
    if (!isStored(audioId: audioId)) throw SongNotStoredException();
    final dir = Directory(MusicData.getDirectoryPath(audioId));
    await dir.delete(recursive: true);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> uninstallSongs(List<String> audioIds) async {
    final futures = audioIds.map((id) => uninstall(id));
    await Future.wait(futures);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> delete(String audioId, {bool saveDataFile = true}) async {
    Future<void> deleteFromDataFile() async {
      musicData.delete(key: audioId);
      if (saveDataFile) {
        await musicData.save(compact: compact);
        await CloudFirestoreManager.removeSongs([audioId]);
      }
    }

    await Future.wait([uninstall(audioId), deleteFromDataFile()]);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> deleteSongs(List<String> audioIds) async {
    final futures = audioIds.map((id) => delete(id, saveDataFile: false));
    await Future.wait(futures);
    await musicData.save(compact: compact);
    await CloudFirestoreManager.removeSongs(audioIds);
  }

  static List<MusicData> getAll({required bool isTemporary}) {
    final data = Map<String, dynamic>.from(musicData.getValue());
    return data.values
        .map((e) => MusicData.fromJson(
              json: e,
              key: const Uuid().v4(),
              isTemporary: isTemporary,
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
    final songs = musicData.getValue() as Map<String, dynamic>;
    return songs.keys.toList();
  }

  static MusicData getByAudioId({
    required String audioId,
    required String key,
    required bool isTemporary,
  }) {
    if (!musicData.has(audioId)) throw LocalSongNotFoundException(audioId);
    final data = musicData.getValue(audioId) as Map<String, dynamic>;
    return MusicData.fromJson(json: data, key: key, isTemporary: isTemporary);
  }
}

extension LocalMusicsDataExtension on MusicData {
  /// Throws [NetworkException] if the network is not accessible.
  Future<void> download() async {
    await LocalMusicsData.download(this);
  }

  Future<void> store() async {
    await LocalMusicsData.store(this);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  Future<void> install() async {
    await LocalMusicsData.install(this);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  Future<void> unistall() async {
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
