import 'dart:io';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../music/audio_source/music_data.dart';
import '../music/utils/music_data_utils.dart';
import 'exceptions/invalid_type_of_media_url_exception.dart';
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

    final List<MusicData<CachingDisabled>> musicDataList = [];
    try {
      musicDataList.add(await MusicDataUtils.fetchFromUrl(text));
    } on InvalidTypeOfMediaUrlException {
      try {
        await for (final musicData
            in MusicDataUtils.fetchPlaylistFromUrl(text)) {
          musicDataList.add(musicData);
        }
      } catch (e) {
        // TODO: handle exception
        return;
      }
    }

    await HomeScreenMusicManager.addSongs(
      count: musicDataList.length,
      musicDataList: musicDataList,
    );
  }
}
