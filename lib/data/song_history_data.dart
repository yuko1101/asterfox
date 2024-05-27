import 'dart:io';

import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/manager/music_manager.dart';
import '../utils/config_file.dart';

class SongHistoryData {
  static late ConfigFile historyData;

  static const bool _compact = false;

  static Future<void> init(MusicManager manager) async {
    historyData =
        await ConfigFile(File("$localPath/history.json"), {"history": []})
            .load();

    // when song is played, add it to history.
    manager.audioStateManager.currentSongNotifier.addListener(() {
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
    data.removeWhere((element) => element["audioId"] == song.audioId);
    final toSave = {
      "audioId": song.audioId,
      "title": song.title,
      "author": song.author,
      "lastPlayed": DateTime.now().millisecondsSinceEpoch,
    };
    data.add(toSave);
    historyData.set(key: "history", value: data);
    await saveData();
  }

  static List<Map<String, dynamic>> getAll({required bool isTemporary}) {
    final data = historyData.getValue("history") as List;
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<void> remove(String audioId) async {
    final data = historyData.getValue("history") as List<dynamic>;
    data.removeWhere((element) => element["audioId"] == audioId);
    historyData.set(key: "history", value: data);
    await saveData();
  }

  static Future<void> removeMultiple(List<String> audioIds) async {
    final data = historyData.getValue("history") as List<dynamic>;
    data.removeWhere((element) => audioIds.contains(element["audioId"]));
    historyData.set(key: "history", value: data);
    await saveData();
  }

  static Future<void> clear() async {
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
    return song["lastPlayed"] as int;
  }

  MusicData renew({required String key, required bool? isTemporary}) {
    return MusicData.fromJson(
      json: toJson(),
      key: key,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }
}
