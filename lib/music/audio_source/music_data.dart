import 'package:asterfox/music/audio_source/youtube_music_data.dart';
import 'package:audio_service/audio_service.dart';
import 'package:easy_app/easy_app.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';

class MusicData {
  MusicData({
    required this.type,
    required this.url,
    required this.remoteUrl,
    required this.imageUrl,
    required this.remoteImageUrl,
    required this.title,
    required this.description,
    required this.author,
    required this.keywords,
    required this.audioId,
    required this.duration,
    required this.isLocal,
    required this.volume,
    required this.key,
  }) {
    _created.add(this);
}
  final MusicType type;
  final String title;
  final String description;
  final String author;
  final List<String> keywords;
  String url; // can be changed if the url is expired (especially for YouTube), or the song saved locally.
  String imageUrl; // can be changed on saving to local storage.
  late String audioId;
  Duration duration; // can be changed on clip-cut.
  bool isLocal; // can be changed on saving to local storage.
  double volume; // can be changed on volume change.
  final String key;
  String remoteUrl;
  String remoteImageUrl;


  MediaItem toMediaItem() {
    return MediaItem(
      id: key,
      title: title,
      artist: author,
      duration: duration,
      displayDescription: description,
      extras: {
        "url": url,
      }
    );
  }

  String get mediaURL => remoteUrl;

  String get savePath => "${EasyApp.localPath}/music/$key.mp3";

  void destroy() {
    _created.remove(this);
  }

  factory MusicData.fromKey(String key) {
    return _created.firstWhere((element) => element.key == key);
  }

   Map<String, dynamic> toJson() {
    final json = {
      'type': type.name,
      'url': savePath,
      'remoteUrl': remoteUrl,
      'imageUrl': imageUrl,
      'remoteImageUrl': remoteImageUrl,
      'title': title,
      'description': description,
      'author': author,
      'audioId': audioId,
      'duration': duration.inMilliseconds,
      'keywords': keywords,
      'volume': volume,
    };
    jsonExtras.forEach((key, value) {
      json[key] = value;
    });
    return json;
  }

  Map<String, dynamic> get jsonExtras => {};

  factory MusicData.fromJson(Map<String, dynamic> json, bool local, String key) {
    final type = MusicType.values.firstWhere((musicType) => musicType.name == json['type'] as String);
    switch (type) {
      case MusicType.youtube:
        return YouTubeMusicData.fromJson(json, local, key);
      default:
        return MusicData(
          key: key,
          type: type,
          url: json['url'] as String,
          remoteUrl: json['remoteUrl'] as String,
          imageUrl: json['imageUrl'] as String,
          remoteImageUrl: json['remoteImageUrl'] as String,
          title: json['title'] as String,
          description: json['description'] as String,
          author: json['author'] as String,
          audioId: json['audioId'] as String,
          duration: Duration(milliseconds: json['duration'] as int),
          isLocal: local,
          keywords: (json['keywords'] as List).map((e) => e as String).toList(),
          volume: json['volume'] as double,
        );
    }
  }




  Future<String?> refreshURL() async {
    return null;
  }

  Future<bool> isUrlAvailable() async {
    return true;
  }

}


List<MusicData> _created = [];

enum MusicType {
  youtube,
  custom
}

extension MusicTypeExtension on MusicType {
  String get name {
    switch (this) {
      case MusicType.youtube:
        return "youtube";
      case MusicType.custom:
        return "custom";
    }
  }
}


extension MediaItemParseMusicData on MediaItem {
  MusicData toMusicData() {
    return _created.firstWhere((musicData) => musicData.key == id);
  }
}

extension AudioSourceParseMusicData on IndexedAudioSource {
  MusicData toMusicData() {
    return _created.firstWhere((musicData) => musicData.key == tag["key"]);
  }
}