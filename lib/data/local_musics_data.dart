import 'dart:io';

import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/utils/extensions.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';
import 'package:uuid/uuid.dart';

import '../music/music_downloader.dart';

class LocalMusicsData {
  static late ConfigFile musicData;

  static const bool _compact = false;

  static Future<void> init() async {
    musicData = await ConfigFile(File("${EasyApp.localPath}/music.json"), {}).load();
  }

  static Future<void> saveData() async {
    await musicData.save(compact: _compact);
  }

  static Future<void> save(MusicData song) async {

    if (!song.isLocal) {
      song.isLocal = true;
      await musicData.set(key: song.audioId, value: song.toJson()).save(compact: _compact);
    }
  }

  static List<MusicData> getAll() {
    final data = musicData.getValue(null) as Map<String, dynamic>;
    return data.values.map((e) => MusicData.fromJson(e, true, const Uuid().v4())).toList();
  }
  
  static List<String> getYouTubeIds() {
    final data = musicData.getValue(null) as Map<String, dynamic>;
    return data.values.where((element) => element["type"] == MusicType.youtube.name).map((e) => e["id"] as String).toList();
  }

  static MusicData? getByAudioId(String? id, String key) {
    if (id == null || !musicData.has(id)) return null;
    final data = musicData.getValue(id) as Map<String, dynamic>;
    return MusicData.fromJson(data, true, key);
  }

  static bool isSaved({MusicData? song, String? audioId}) {
    if (song == null && audioId == null) throw ArgumentError("song or audioId must be not null");
    return musicData.has(song?.audioId ?? audioId!);
  }

  static Future<void> removeFromLocal(MusicData song) async {
    if (!song.isLocal) return;
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
  Future<void> save() async {
    await MusicDownloader.download(this);
  }

  bool get isSaved => LocalMusicsData.isSaved(song: this);
}