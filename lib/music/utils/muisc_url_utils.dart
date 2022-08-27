import 'package:asterfox/music/utils/youtube_music_utils.dart';
import 'package:asterfox/system/exceptions/invalid_type_of_media_url_exception.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../audio_source/music_data.dart';

class MusicUrlUtils {
  /// This method may occurs some errors or exceptions.
  ///
  /// Specific errors and exceptions depends on type of url.
  ///
  /// The method used by each type of URL is as follows.
  ///
  /// YouTube: [YouTubeMusicUtils.getYouTubeAudio]
  static Future<MusicData> createMusicDataFromUrl({
    required String mediaUrl,
    required String key,
    bool isTemporary = false,
  }) async {
    if (!mediaUrl.isUrl) {
      throw ArgumentError.value(
          mediaUrl, "Invalid URL", "`mediaUrl` is not a valid url");
    }
    if (mediaUrl.isYouTubeUrl) {
      return await YouTubeMusicUtils.getYouTubeAudio(
        videoId: VideoId(mediaUrl).value,
        key: key,
        isTemporary: isTemporary,
      );
    }
    throw InvalidTypeOfMediaUrlException(mediaUrl);
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
