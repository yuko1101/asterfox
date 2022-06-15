import 'package:asterfox/main.dart';
import 'package:asterfox/system/home_screen_music_manager.dart';
import 'package:asterfox/utils/youtube_music_utils.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SharingIntent {
  static void init() {
    ReceiveSharingIntent.getTextStream().listen((text) => addSong(text, false));

    ReceiveSharingIntent.getInitialText().then((text) => addSong(text, true));
  }

  static Future<void> addSong(String? text, bool initial) async {
    Fluttertoast.showToast(msg: "${initial ? "Initial " : ""}Loading from $text");
    if (text == null) return;

    final isPlaylist = await loadPlaylist(text);
    if (isPlaylist) return;

    VideoId id;
    try {
      id = VideoId(text);
    } on ArgumentError {
      Fluttertoast.showToast(msg: Language.getText("invalid_url"));
      return;
    }
    HomeScreenMusicManager.addSong(key: const Uuid().v4(), youtubeId: id.value);
  }

  static final RegExp playlistRegex = RegExp(r"^https?://(www.)?youtube.com/playlist\?((.+=.+&)*)list=([^&]+)");
  static Future<bool> loadPlaylist(String text) async {
    if (!playlistRegex.hasMatch(text)) {
      return false;
    }
    final match = playlistRegex.firstMatch(text)!;
    final listId = match.group(4)!;
    final yt = YoutubeExplode();
    final playlist = await yt.playlists.get(listId);
    if (playlist.videoCount == null || playlist.videoCount == 0) {
      Fluttertoast.showToast(msg: Language.getText("external_playlist_empty"));
      return true;
    }
    await HomeScreenMusicManager.addSongs(count: playlist.videoCount!, youtubePlaylist: listId);
    return true;
  }
}