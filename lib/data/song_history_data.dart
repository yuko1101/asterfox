import 'dart:io';

import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/manager/music_manager.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';

class SongHistoryData {
  static late ConfigFile historyData;

  static const bool _compact = false;

  static Future<void> init(MusicManager manager) async {
    historyData = await ConfigFile(File("${EasyApp.localPath}/history.json"), {"history": []}).load();

    // when song is played, add it to history.
    manager.currentSongNotifier.addListener(() {
      if (manager.audioDataManager.currentSong != null) addAndSave(manager.audioDataManager.currentSong!);
    });
  }

  static Future<void> saveData() async {
    await historyData.save(compact: _compact);
  }

  static Future<void> addAndSave(MusicData song) async {
    final data = historyData.getValue("history") as List<dynamic>;
    data.removeWhere((element) => element["id"] == song.audioId);
    final toSave = song.toJson();
    toSave["last_played"] = DateTime.now().millisecondsSinceEpoch;
    data.add(toSave);
    await historyData.set(key: "history", value: data).save(compact: _compact);
  }

  static List<MusicData> getAll() {
    final data = historyData.getValue("history") as List<dynamic>;
    return data.map((e) => MusicData.fromJson(e, true)).toList();
  }

  static Future<void> removeFromHistory(MusicData song) async {
    final data = historyData.getValue("history") as List<dynamic>;
    data.removeWhere((element) => element["audioId"] == song.audioId);
    await historyData.set(key: "history", value: data).save(compact: _compact);
  }

  static Future<void> removeAllFromHistory(List<MusicData> songs) async {
    final data = historyData.getValue("history") as List<dynamic>;
    data.removeWhere((element) => songs.any((e) => e.audioId == element["audioId"]));
    await historyData.set(key: "history", value: data).save(compact: _compact);
  }

  static Future<void> clearHistory() async {
    await historyData.set(key: "history", value: []).save(compact: _compact);
  }
}

extension SongHistoryDataExtension on MusicData {
  int? get lastPlayed {
    final data = SongHistoryData.historyData.getValue("history") as List<dynamic>;
    final song = data.firstWhere((element) => element["audioId"] == audioId, orElse: () => null);
    if (song == null) return null;
    return song["last_played"] as int;
  }
}