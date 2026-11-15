import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../main.dart';
import '../music/music_data/music_data.dart';
import '../music/utils/music_data_utils.dart';
import '../utils/os.dart';
import 'home_screen_music_manager.dart';

class SharingIntent {
  static void init() {
    if (OS.isAndroid || OS.isIOS) {
      ReceiveSharingIntent.instance.getMediaStream().listen(addSongs);
      ReceiveSharingIntent.instance.getInitialMedia().then(addSongs);
    }
  }

  /// Adds the songs of what was shared to the app: a url of a song or of a
  /// playlist, or a text to search for.
  static Future<void> addSongs(List<SharedMediaFile> mediaList) async {
    final List<MusicData<CachingDisabled>> musicDataList = [];

    for (final media in mediaList) {
      final isText = media.type == SharedMediaType.text;
      if (media.type != SharedMediaType.url && !isText) continue;
      try {
        // A text that is not a url is searched for, and a url that is not a
        // song is tried as a playlist.
        musicDataList.addAll(await MusicDataUtils.searchList(media.path));
      } catch (e) {
        debugPrint("[Asterfox] failed to load the shared ${media.path}: $e");
      }
    }

    if (musicDataList.isEmpty) {
      if (mediaList.isNotEmpty && l10n.isInitialized) {
        Fluttertoast.showToast(msg: l10n.value.something_went_wrong);
      }
      return;
    }
    await HomeScreenMusicManager.addSongs(musicDataList: musicDataList);
  }
}
