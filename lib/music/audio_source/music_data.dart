import 'package:audio_service/audio_service.dart';
import 'package:easy_app/easy_app.dart';
import 'package:just_audio/just_audio.dart';

import 'youtube_music_data.dart';

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
    this.isTemporary = false,
  }) {
    print("MusicData created : temp = $isTemporary");
    if (isTemporary) return;
    print("MusicData: {key: $key, title: $title}");
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

  final bool isTemporary;


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
  String get imageSavePath => "${EasyApp.localPath}/images/$key.png";

  void destroy() {
    _created.remove(this);
    print("MusicData destroyed : remaining = ${_created.length}");
  }

  factory MusicData.fromKey(String key) {
    return _created.firstWhere((element) => element.key == key);
  }

   Map<String, dynamic> toJson() {
    final json = {
      'type': type.name,
      'url': url,
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

  factory MusicData.fromJson({
    required Map<String, dynamic> json,
    required bool isLocal,
    required String key,
    bool isTemporary = false,
  }) {
    final type = MusicType.values.firstWhere((musicType) => musicType.name == json['type'] as String);
    switch (type) {
      case MusicType.youtube:
        return YouTubeMusicData.fromJson(json: json, isLocal: isLocal, key: key, isTemporary: isTemporary);
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
          isLocal: isLocal,
          keywords: (json['keywords'] as List).map((e) => e as String).toList(),
          volume: json['volume'] as double,
          isTemporary: isTemporary,
        );
    }


  }

  Future<String?> refreshURL() async {
    return null;
  }

  Future<bool> isUrlAvailable() async {
    return true;
  }

  static final List<MusicData> _created = [];
  static List<MusicData> getCreated() {
    return _created;
  }

  static void clearCreated() {
    _created.clear();
  }

  static void deleteCreated(String key) {
    _created.removeWhere((song) => song.key == key);
  }

}

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
    return MusicData.getCreated().firstWhere((musicData) => musicData.key == id);
  }
}

extension AudioSourceParseMusicData on IndexedAudioSource {
  MusicData toMusicData() {
    return MusicData.getCreated().firstWhere((musicData) => musicData.key == tag["key"]);
  }
}