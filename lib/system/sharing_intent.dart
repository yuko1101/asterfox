import 'package:asterfox/main.dart';
import 'package:asterfox/system/home_screen_music_manager.dart';
import 'package:asterfox/util/youtube_music_utils.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../music/audio_source/youtube_audio.dart';

class SharingIntent {
  static void init() {
    ReceiveSharingIntent.getTextStream().listen(addSong);

    ReceiveSharingIntent.getInitialText().then(addSong);
  }

  static Future<void> addSong(String? text) async {
    if (text == null) return;
    VideoId id;
    try {
      id = VideoId(text);
    } catch (e) {
      Fluttertoast.showToast(msg: "無効なURLです");
      return;
    }
    HomeScreenMusicManager.addSongByID(id.value);
  }
}