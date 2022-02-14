import 'package:asterfox/main.dart';
import 'package:asterfox/music/youtube_music.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../music/audio_source/youtube_audio.dart';

class SharingIntent {
  static void init() {
    ReceiveSharingIntent.getTextStream().listen((String text) async {
      VideoId id;
      try {
        id = VideoId(text);
      } catch (e) {
        Fluttertoast.showToast(msg: "無効なURLです");
        return;
      }
      final YouTubeAudio? song = await getYouTubeAudio(id.value);
      if (song == null) return;
      await musicManager.add(song);
    });
  }
}