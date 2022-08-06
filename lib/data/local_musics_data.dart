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
import '../utils/extensions.dart';

// TODO: add install system which enables you to download particular songs in music.json (https://github.com/yuko1101/asterfox/issues/29)
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

  static Future<void> store(MusicData song) async {
    if (!song.isDataStored) {
      song.isDataStored = true;
      musicData.set(key: song.audioId, value: song.toJson());
      await saveData();
    }
  }

  static List<MusicData> getAll({bool isTemporary = false}) {
    final data = musicData.getValue(null) as Map<String, dynamic>;
    return data.values
        .map((e) => MusicData.fromJson(
              json: e,
              isLocal: true,
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
    return MusicData.fromJson(
        json: data, isLocal: true, key: key, isTemporary: isTemporary);
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

  static Future<void> removeFromLocal(MusicData song) async {
    if (!song.isStored) return;
    final file = File(song.audioSavePath);
    imageDelete() async {
      String url = song.imageSavePath;
      if (!url.isUrl) {
        final file = File(url);
        if (file.existsSync()) await file.delete();
      }
    }

    musicData.delete(key: song.audioId);
    final futures = [file.delete(), imageDelete(), saveData()];
    await Future.wait(futures);
  }

  static Future<void> removeAllFromLocal(List<MusicData> songs) async {
    final futures = songs.map((e) => removeFromLocal(e));
    await Future.wait(futures);
  }
}

extension LocalMusicsDataExtension on MusicData {
  /// Throws [NetworkException] if the network is not accessible.
  Future<void> download({bool storeToJSON = true}) async {
    if (isStored) return;
    await MusicDownloader.download(this, storeToJson: storeToJSON);
  }

  Future<void> store() async {
    if (isStored) return;
    await LocalMusicsData.store(this);
  }

  /// Throws [SongNotStoredException] if the song is not stored.
  Future<void> install() async {
    if (!isStored) throw SongNotStoredException();
    if (isInstalled) return;
    await MusicDownloader.download(this, storeToJson: false);
  }

  bool get isStored => LocalMusicsData.isStored(song: this);
  bool get isInstalled => LocalMusicsData.isInstalled(song: this);

  Future<String> get audioUrl async =>
      isInstalled ? audioSavePath : await getAvailableAudioUrl();

  String get cachedAudioUrl => isInstalled ? audioSavePath : remoteAudioUrl;

  String get imageUrl => isInstalled ? imageSavePath : remoteImageUrl;
}
