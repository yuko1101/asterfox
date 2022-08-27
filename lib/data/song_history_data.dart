import 'dart:io';

import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';
import 'package:uuid/uuid.dart';

import '../music/audio_source/music_data.dart';
import '../music/manager/music_manager.dart';

class SongHistoryData {
  static late ConfigFile historyData;

  static const bool _compact = false;

  static Future<void> init(MusicManager manager) async {
    historyData = await ConfigFile(
        File("${EasyApp.localPath}/history.json"), {"history": []}).load();

    // when song is played, add it to history.
    manager.currentSongNotifier.addListener(() {
      if (manager.audioDataManager.currentSong != null) {
        addAndSave(manager.audioDataManager.currentSong!);
      }
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
    historyData.set(key: "history", value: data);
    await saveData();
  }

  static List<MusicData> getAll({bool isTemporary = false}) {
    final data = historyData.getValue("history") as List<dynamic>;
    return data
        .map((e) => MusicData.fromJson(
              json: e,
              key: const Uuid().v4(),
              isTemporary: isTemporary,
            ))
        .toList();
  }

  static Future<void> removeFromHistory(MusicData song) async {
    final data = historyData.getValue("history") as List<dynamic>;
    data.removeWhere((element) => element["audioId"] == song.audioId);
    historyData.set(key: "history", value: data);
    await saveData();
  }

  static Future<void> removeAllFromHistory(List<MusicData> songs) async {
    final data = historyData.getValue("history") as List<dynamic>;
    data.removeWhere(
        (element) => songs.any((e) => e.audioId == element["audioId"]));
    historyData.set(key: "history", value: data);
    await saveData();
  }

  static Future<void> clearHistory() async {
    historyData.set(key: "history", value: []);
    await saveData();
  }
}

extension SongHistoryDataExtension on MusicData {
  int? get lastPlayed {
    final data =
        SongHistoryData.historyData.getValue("history") as List<dynamic>;
    final song = data.firstWhere((element) => element["audioId"] == audioId,
        orElse: () => null);
    if (song == null) return null;
    return song["last_played"] as int;
  }

  MusicData renew({required String key, required bool? isTemporary}) {
    return MusicData.fromJson(
      json: toJson(),
      key: key,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }
}
