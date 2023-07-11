import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../system/exceptions/invalid_type_of_media_url_exception.dart';
import '../audio_source/music_data.dart';

class MusicUrlUtils {
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
