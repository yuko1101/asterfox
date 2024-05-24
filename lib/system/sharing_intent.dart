import 'dart:io';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'home_screen_music_manager.dart';

class SharingIntent {
  static void init() {
    if (Platform.isAndroid || Platform.isIOS) {
      ReceiveSharingIntent.instance.getMediaStream().listen((mediaList) {});

      ReceiveSharingIntent.instance.getInitialMedia().then((mediaList) {});
    }
  }

  static Future<void> addSong(
      String? text, bool initial, BuildContext context) async {
    // Fluttertoast.showToast(msg: "${initial ? "Initial " : ""}Loading from $text");
    if (text == null) return;
    HomeScreenMusicManager.addSongBySearch(text);
  }
}
