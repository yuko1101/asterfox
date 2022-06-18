import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'home_screen_music_manager.dart';

class SharingIntent {
  static void init() {
    ReceiveSharingIntent.getTextStream().listen((text) => addSong(text, false));

    ReceiveSharingIntent.getInitialText().then((text) => addSong(text, true));
  }

  static Future<void> addSong(String? text, bool initial) async {
    // Fluttertoast.showToast(msg: "${initial ? "Initial " : ""}Loading from $text");
    if (text == null) return;
    HomeScreenMusicManager.addSongBySearch(text);
  }
}
