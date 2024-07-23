import '../../music/music_data/music_data.dart';
import '../../music/utils/music_data_utils.dart';

abstract class Suggestion {
  Suggestion({
    required this.title,
    this.subtitle,
    required this.keywords,
  });

  final String title;
  final String? subtitle;
  final List<String> keywords;

  bool isSameSuggestion(Suggestion other) =>
      (_isSameAudioId(other) || _isSameUrl(other) || _isSameWord(other));

  bool _isSameAudioId(Suggestion other) =>
      this is SongSuggestion &&
      other is SongSuggestion &&
      (this as SongSuggestion).musicData != null &&
      other.musicData != null &&
      (this as SongSuggestion).musicData?.audioId == other.musicData?.audioId;

  bool _isSameUrl(Suggestion other) =>
      this is SongSuggestion &&
      other is SongSuggestion &&
      (this as SongSuggestion).mediaUrl != null &&
      other.mediaUrl != null &&
      (this as SongSuggestion).mediaUrl == other.mediaUrl;

  bool _isSameWord(Suggestion other) =>
      this is WordSuggestion &&
      other is WordSuggestion &&
      (this as WordSuggestion).word == other.word;
}

class WordSuggestion extends Suggestion {
  WordSuggestion({
    required this.word,
    required super.title,
    super.subtitle,
    required super.keywords,
  });

  final String word;
}

class SongSuggestion extends Suggestion {
  SongSuggestion({
    this.musicData,
    this.mediaUrl,
    required this.tags,
    required super.title,
    super.subtitle,
    required super.keywords,
    this.lyrics,
  }) {
    assert(musicData != null || mediaUrl != null);
  }

  final MusicData<CachingDisabled>? musicData;
  final String? mediaUrl;

  final List<SongTag> tags;
  final String? lyrics;

  Future<MusicData<CachingDisabled>> fetchMusicData() async {
    if (musicData != null) {
      return musicData!;
    }
    return MusicDataUtils.fetchFromUrl(mediaUrl!);
  }
}

enum SongTag { installed, stored, youtube }
