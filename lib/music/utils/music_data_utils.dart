import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../system/exceptions/invalid_type_of_media_url_exception.dart';
import '../audio_source/music_data.dart';
import 'youtube_music_utils.dart';

class MusicDataUtils {
  static String getAudioId({
    String? audioId,
    String? mediaUrl,
    MusicData? musicData,
  }) {
    assert(audioId != null || mediaUrl != null || musicData != null);
    return audioId ?? musicData?.audioId ?? getAudioIdFromUrl(mediaUrl!);
  }

  static String getAudioIdFromUrl(String mediaUrl) {
    if (!mediaUrl.isUrl) {
      throw ArgumentError.value(
          mediaUrl, "Invalid URL", "`mediaUrl` is not a valid url");
    }
    if (mediaUrl.isYouTubeUrl) {
      return VideoId(mediaUrl).value;
    }
    throw InvalidTypeOfMediaUrlException(mediaUrl);
  }

  static Future<MusicData<CachingDisabled>> search(String query) async {
    if (query.isUrl) {}
    final list = await YouTubeMusicUtils.searchYouTubeVideo(query);

    return list.first.fetchMusicData(
      key: const Uuid().v4(),
      caching: CachingDisabled(),
    );
  }

  static Future<MusicData<CachingDisabled>> fetchFromUrl(String url) {
    final audioId = getAudioIdFromUrl(url);
    return MusicData.getByAudioId(
      audioId: audioId,
      key: const Uuid().v4(),
      caching: CachingDisabled(),
    );
  }

  static final RegExp playlistRegex =
      RegExp(r"^https?://(www.)?youtube.com/playlist\?((.+=.+&)*)list=([^&]+)");
  static Stream<MusicData<CachingDisabled>> fetchPlaylistFromUrl(String url) {
    final match = playlistRegex.firstMatch(url);
    if (match == null) {
      throw ArgumentError.value(
          url, "Invalid URL", "The URL is not a valid YouTube playlist URL");
    }
    final playlistId = match.group(4)!;

    return YouTubeMusicUtils.getMusicDataFromPlaylist(
        playlistId: playlistId, caching: CachingDisabled());
  }
}

final _httpRegex = RegExp(r'^https?:\/\/.+$');

extension StringExtension on String {
  bool get isUrl => _httpRegex.hasMatch(this);
  bool get isYouTubeUrl {
    try {
      VideoId(this);
      return true;
    } on ArgumentError {
      return false;
    }
  }
}
