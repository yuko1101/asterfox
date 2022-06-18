import 'dart:io';

import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';
import 'package:uuid/uuid.dart';

import '../music/audio_source/music_data.dart';
import '../music/music_downloader.dart';
import '../system/exceptions/local_song_not_found_exception.dart';
import '../utils/extensions.dart';

class LocalMusicsData {
  static late ConfigFile musicData;

  static const bool _compact = false;

  static Future<void> init() async {
    musicData =
        await ConfigFile(File("${EasyApp.localPath}/music.json"), {}).load();
  }

  static Future<void> saveData() async {
    await musicData.save(compact: _compact);
  }

  static Future<void> save(MusicData song) async {
    if (!song.isLocal) {
      song.isLocal = true;
      await musicData
          .set(key: song.audioId, value: song.toJson())
          .save(compact: _compact);
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

  static bool isSaved({MusicData? song, String? audioId}) {
    assert(song != null || audioId != null);
    return musicData.has(song?.audioId ?? audioId!);
  }

  static Future<void> removeFromLocal(MusicData song) async {
    if (!song.isSaved) return;
    final file = File(song.savePath);
    final imageDelete = () async {
      String url = song.imageUrl;
      if (!url.isUrl) {
        final file = File(url);
        if (file.existsSync()) await file.delete();
      }
    }();
    musicData.delete(key: song.audioId);
    final futures = [file.delete(), imageDelete, saveData()];
    await Future.wait(futures);
  }

  static Future<void> removeAllFromLocal(List<MusicData> songs) async {
    final futures = songs.map((e) => removeFromLocal(e));
    await Future.wait(futures);
  }
}

extension LocalMusicsDataExtension on MusicData {
  Future<void> save({bool saveToJSON = true}) async {
    if (isSaved) return;
    await MusicDownloader.download(this, saveToJSON: saveToJSON);
  }

  bool get isSaved => LocalMusicsData.isSaved(song: this);

  // 保存されている場合、URL等を保存されてるものに更新する
  void loadLocal() {
    if (!isSaved) return;
    url = savePath;
    imageUrl = imageSavePath;
    isLocal = true;
  }
}
