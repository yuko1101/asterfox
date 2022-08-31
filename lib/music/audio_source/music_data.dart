import 'package:asterfox/music/audio_source/url_music_data.dart';
import 'package:audio_service/audio_service.dart';
import 'package:easy_app/easy_app.dart';
import 'package:just_audio/just_audio.dart';

import 'youtube_music_data.dart';
import '../../data/local_musics_data.dart';

class MusicData {
  MusicData({
    required this.type,
    required this.remoteAudioUrl,
    required this.remoteImageUrl,
    required this.title,
    required this.description,
    required this.author,
    required this.keywords,
    required this.audioId,
    required this.duration,
    required this.volume,
    required this.lyrics,
    required this.songStoredAt,
    required this.size,
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
  final String audioId;
  Duration duration; // can be changed on clip-cut.
  double volume; // can be changed on volume change.
  String lyrics;
  int? songStoredAt;
  int? size; // file size in Bytes
  final String key;
  String remoteAudioUrl;
  String remoteImageUrl;

  final bool isTemporary;

  Future<MediaItem> toMediaItem() async {
    return MediaItem(
      id: key,
      title: title,
      artist: author,
      duration: duration,
      displayDescription: description,
      extras: {
        "url": await audioUrl,
      },
    );
  }

  String get mediaURL => remoteAudioUrl;

  String get directoryPath => getDirectoryPath(audioId);
  String get audioSavePath => getAudioSavePath(audioId);
  String get imageSavePath => getImageSavePath(audioId);
  String get installCompleteFilePath => getInstallCompleteFilePath(audioId);

  void destroy() {
    _created.remove(this);
    print("MusicData destroyed : remaining = ${_created.length}");
  }

  factory MusicData.fromKey(String key) {
    return _created.firstWhere((element) => element.key == key);
  }

  Map<String, dynamic> toJson() {
    final json = {
      "type": type.name,
      "remoteAudioUrl": remoteAudioUrl,
      "remoteImageUrl": remoteImageUrl,
      "title": title,
      "description": description,
      "author": author,
      "audioId": audioId,
      "duration": duration.inMilliseconds,
      "keywords": keywords,
      "volume": volume,
      "lyrics": lyrics,
      "songStoredAt": songStoredAt,
      "size": size,
    };
    jsonExtras.forEach((key, value) {
      json[key] = value;
    });
    return json;
  }

  Map<String, dynamic> get jsonExtras => {};

  factory MusicData.fromJson({
    required Map<String, dynamic> json,
    required String key,
    bool isTemporary = false,
  }) {
    final type = MusicType.values
        .firstWhere((musicType) => musicType.name == json["type"] as String);
    switch (type) {
      case MusicType.youtube:
        return YouTubeMusicData.fromJson(
          json: json,
          key: key,
          isTemporary: isTemporary,
        );
      case MusicType.url:
        return UrlMusicData.fromJson(
          json: json,
          key: key,
          isTemporary: isTemporary,
        );
      // default:
      //   return MusicData(
      //     key: key,
      //     type: type,
      //     remoteAudioUrl: json["remoteAudioUrl"] as String,
      //     remoteImageUrl: json["remoteImageUrl"] as String,
      //     title: json["title"] as String,
      //     description: json["description"] as String,
      //     author: json["author"] as String,
      //     audioId: json["audioId"] as String,
      //     duration: Duration(milliseconds: json["duration"] as int),
      //     isDataStored: isLocal,
      //     keywords: (json["keywords"] as List).map((e) => e as String).toList(),
      //     volume: json["volume"] as double,
      //     lyrics: json["lyrics"] as String,
      //     isTemporary: isTemporary,
      //   );
    }
  }

  Future<String> refreshAudioURL() async {
    return remoteAudioUrl;
  }

  Future<bool> isAudioUrlAvailable() async {
    return true;
  }

  Future<String> getAvailableAudioUrl() async {
    if (await isAudioUrlAvailable()) return remoteAudioUrl;
    return await refreshAudioURL();
  }

  static String getDirectoryPath(String audioId) =>
      "${EasyApp.localPath}/music/$audioId";
  static String getAudioSavePath(String audioId) =>
      "${getDirectoryPath(audioId)}/audio.mp3";
  static String getImageSavePath(String audioId) =>
      "${getDirectoryPath(audioId)}/image.png";
  static String getInstallCompleteFilePath(String audioId) =>
      "${getDirectoryPath(audioId)}/installed.txt";

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

enum MusicType { youtube, url }

extension MusicTypeExtension on MusicType {
  String get name {
    switch (this) {
      case MusicType.youtube:
        return "youtube";
      case MusicType.url:
        return "raw";
    }
  }
}

extension MediaItemParseMusicData on MediaItem {
  MusicData toMusicData() {
    return MusicData.getCreated()
        .firstWhere((musicData) => musicData.key == id);
  }
}

extension AudioSourceParseMusicData on IndexedAudioSource {
  MusicData toMusicData() {
    return MusicData.getCreated()
        .firstWhere((musicData) => musicData.key == tag["key"]);
  }
}
