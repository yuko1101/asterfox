import 'dart:io';

import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';
import 'package:uuid/uuid.dart';

import '../music/audio_source/music_data.dart';
import '../music/manager/music_manager.dart';
import '../system/exceptions/local_song_not_found_exception.dart';
import '../system/exceptions/refresh_url_failed_exception.dart';
import '../utils/network_check.dart';
import 'local_musics_data.dart';

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

  static List<MusicData> getAll({bool isTemporary = false}) {
    final data = historyData.getValue("history") as List<dynamic>;
    return data.map((e) => MusicData.fromJson(
      json: e,
      isLocal: LocalMusicsData.isSaved(audioId: e["audioId"]),
      key:  const Uuid().v4(),
      isTemporary: isTemporary,
    )).toList();
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

  // ローカルストレージに保存されている場合は、LocalMusicsDataから読み込み、
  // そうでない場合は、URLを更新して、リモートのMusicDataとして読み込む。
  /// Throws [NetworkException] if network is not accessible.
  ///
  /// Throws [RefreshUrlFailedException] if refresh url failed.
  Future<MusicData> renew(String key, {bool isTemporary = false}) async {
    try {
      final localMusicData =  LocalMusicsData.getByAudioId(audioId: audioId, key: key, isTemporary: isTemporary);
      return localMusicData;
    } on LocalSongNotFoundException {
      // インターネット接続確認
      NetworkCheck.check();

      final url = await isUrlAvailable() ? remoteUrl : await refreshURL();
      // urlを取得できなかった場合は、nullを返す
      if (url == null) throw RefreshUrlFailedException();

      final json = toJson();
      json["url"] = url;
      json["remoteUrl"] = url;

      if ((json["remoteImageUrl"] as String).isEmpty) {
        throw Exception("Cannot resolve image url");
      }
      json["imageUrl"] = json["remoteImageUrl"];

      return MusicData.fromJson(json: json, isLocal: false, key: key, isTemporary: isTemporary);
    }
  }
}