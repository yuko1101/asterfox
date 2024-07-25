import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../music/music_data/music_data.dart';
import '../music/utils/music_data_utils.dart';
import '../utils/os.dart';
import 'exceptions/invalid_type_of_media_url_exception.dart';
import 'home_screen_music_manager.dart';

class SharingIntent {
  static void init() {
    if (OS.isAndroid || OS.isIOS) {
      ReceiveSharingIntent.instance.getMediaStream().listen((mediaList) {
        addSongs(mediaList, false);
      });

      ReceiveSharingIntent.instance.getInitialMedia().then((mediaList) {
        addSongs(mediaList, true);
      });
    }
  }

  static Future<void> addSongs(
      List<SharedMediaFile> mediaList, bool initial) async {
    // Fluttertoast.showToast(msg: "${initial ? "Initial " : ""}Loading from $text");
    if (mediaList.isEmpty) return;

    final List<MusicData<CachingDisabled>> musicDataList = [];

    for (final media in mediaList) {
      if (media.type == SharedMediaType.url ||
          (media.type == SharedMediaType.text && media.path.isUrl)) {
        musicDataList.addAll(await fetchSongsFromUrl(media.path));
      } else if (media.type == SharedMediaType.text) {
        musicDataList.add(await fetchSongsByQuery(media.path));
      }
    }

    await HomeScreenMusicManager.addSongs(
      count: musicDataList.length,
      musicDataList: musicDataList,
    );
  }

  static Future<MusicData<CachingDisabled>> fetchSongsByQuery(String query) {
    return MusicDataUtils.search(query);
  }

  static Future<List<MusicData<CachingDisabled>>> fetchSongsFromUrl(
      String url) async {
    final List<MusicData<CachingDisabled>> musicDataList = [];

    try {
      musicDataList.add(await MusicDataUtils.fetchFromUrl(url));
    } on InvalidTypeOfMediaUrlException {
      try {
        await for (final musicData
            in MusicDataUtils.fetchPlaylistFromUrl(url)) {
          musicDataList.add(musicData);
        }
      } catch (e) {
        // TODO: handle exception
      }
    }

    return musicDataList;
  }
}
