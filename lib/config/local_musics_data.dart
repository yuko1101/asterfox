import 'dart:io';

import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/audio_source/youtube_audio.dart';
import 'package:asterfox/util/config_file.dart';
import 'package:uuid/uuid.dart';

late ConfigFile localMusicData;

class LocalMusicsData {
  static Future<void> init() async {
    localMusicData = await ConfigFile(File("$localPath/music.json"), {}).load();
  }

  static Future<void> save(AudioBase song) async {

    if (!song.isLocal) {
      await localMusicData.set(key: getSongId(song), value: song.copyAsLocal().toJson()).save();

    }
  }

  static List<AudioBase> getAll() {
    final data = localMusicData.getValue(null) as Map<String, dynamic>;
    return data.values.map((e) => loadFromJson(e, local: true)).toList();
  }
  
  static List<String> getYouTubeIds() {
    final data = localMusicData.getValue(null) as Map<String, dynamic>;
    return data.values.where((element) => element["type"] == YouTubeAudio.classId()).map((e) => e["id"] as String).toList();
  }

  static Future<AudioBase?> getById(String id) async {
    if (!localMusicData.has(id)) return null;
    final data = localMusicData.getValue(id) as Map<String, dynamic>;
    return loadFromJson(data, local: true);
  }


}

String getSongId(AudioBase song) {
  if (song is YouTubeAudio) return song.id;
  return const Uuid().v4().toString();
}