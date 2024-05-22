import 'dart:io';

import '../main.dart';
import '../music/playlist/playlist.dart';
import '../utils/config_file.dart';

class PlaylistsData {
  static late ConfigFile playlistsData;

  static const bool _compact = false;

  static Future<void> init() async {
    playlistsData =
        await ConfigFile(File("$localPath/playlists.json"), {}).load();
  }

  static Future<void> saveData() async {
    await playlistsData.save(compact: _compact);
  }

  static Future<void> addAndSave(AppPlaylist playlist) async {
    playlistsData.set(key: playlist.id, value: playlist.toJson());
    await saveData();
  }

  static List<AppPlaylist> getAll() {
    final data = playlistsData.getValue() as Map<String, dynamic>;
    return data.values
        .map((p) => AppPlaylist.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  static AppPlaylist getById(String id) {
    final data = playlistsData.getValue() as Map<String, dynamic>;
    return AppPlaylist.fromJson(data[id] as Map<String, dynamic>);
  }

  static Future<void> remove(String id) async {
    playlistsData.delete(key: id);
    await saveData();
  }

  static Future<void> removeAll(List<String> ids) async {
    for (final id in ids) {
      playlistsData.delete(key: id);
    }
    await saveData();
  }

  static Future<void> clear() async {
    playlistsData.resetData();
    await saveData();
  }
}
