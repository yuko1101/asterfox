import 'dart:io';

import 'package:asterfox/data/temporary_data.dart';
import 'package:asterfox/system/exceptions/song_not_stored_exception.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';
import 'package:easy_app/utils/network_utils.dart';
import 'package:uuid/uuid.dart';

import '../music/audio_source/music_data.dart';
import '../music/music_downloader.dart';
import '../system/exceptions/local_song_not_found_exception.dart';
import '../system/exceptions/network_exception.dart';
import '../system/firebase/cloud_firestore.dart';

// TODO: add install system which enables you to download particular songs in music.json (https://github.com/yuko1101/asterfox/issues/29)
// TODO: move `remoteAudioUrl` into TemporaryData
class LocalMusicsData {
  static late ConfigFile musicData;

  static const bool _compact = false;

  static Future<void> init() async {
    musicData =
        await ConfigFile(File("${EasyApp.localPath}/music.json"), {}).load();
  }

  static Future<void> saveData() async {
    await musicData.save(compact: _compact);
    if (NetworkUtils.networkConnected()) {
      await CloudFirestoreManager.upload();
    } else {
      TemporaryData.data.set(key: "offline_changes", value: true);
      await TemporaryData.save();
    }
  }

  static bool isStored({MusicData? song, String? audioId}) {
    assert(song != null || audioId != null);
    return musicData.has(song?.audioId ?? audioId!);
  }

  static bool isInstalled({MusicData? song, String? audioId}) {
    assert(song != null || audioId != null);
    return Directory(MusicData.getDirectoryPath(song?.audioId ?? audioId!))
        .existsSync();
  }

  static Future<void> store(MusicData song) async {
    if (song.isStored) return;
    musicData.set(key: song.audioId, value: song.toJson());
    await saveData();
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> install(MusicData song) async {
    if (!song.isStored) throw SongNotStoredException();
    if (song.isInstalled) return;
    await MusicDownloader.download(song, storeToJson: false);
  }

  static Future<void> download(MusicData song,
      {bool storeToJSON = true}) async {
    await MusicDownloader.download(song, storeToJson: storeToJSON);
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
    deleteFromDataFile() async {
      musicData.delete(key: audioId);
      if (saveDataFile) await saveData();
    }

    await Future.wait([uninstall(audioId), deleteFromDataFile()]);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  static Future<void> deleteSongs(List<String> audioIds) async {
    final futures = audioIds.map((id) => delete(id, saveDataFile: false));
    await Future.wait(futures);
    await saveData();
  }

  static List<MusicData> getAll({bool isTemporary = false}) {
    final data = musicData.getValue(null) as Map<String, dynamic>;
    return data.values
        .map((e) => MusicData.fromJson(
              json: e,
              key: const Uuid().v4(),
              isTemporary: isTemporary,
            ))
        .toList();
  }

  static List<String> getYouTubeIds() {
    final data = musicData.getValue(null) as Map<String, dynamic>;
    return data.values
        .where((element) => element["type"] == MusicType.youtube.name)
        .map((e) => e["id"] as String)
        .toList();
  }

  static MusicData getByAudioId({
    required String audioId,
    required String key,
    bool isTemporary = false,
  }) {
    if (!musicData.has(audioId)) throw LocalSongNotFoundException(audioId);
    final data = musicData.getValue(audioId) as Map<String, dynamic>;
    return MusicData.fromJson(json: data, key: key, isTemporary: isTemporary);
  }
}

extension LocalMusicsDataExtension on MusicData {
  /// Throws [NetworkException] if the network is not accessible.
  Future<void> download({bool storeToJSON = true}) async {
    await LocalMusicsData.download(this, storeToJSON: storeToJSON);
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
