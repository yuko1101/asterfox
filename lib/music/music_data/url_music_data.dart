import 'dart:convert';

import 'music_data.dart';

class UrlMusicData<T extends Caching> extends MusicData<T> {
  UrlMusicData({
    required super.remoteAudioUrl,
    required super.remoteImageUrl,
    required super.title,
    required super.description,
    required super.author,
    required super.keywords,
    required super.duration,
    required super.volume,
    required super.lyrics,
    required super.songStoredAt,
    required super.size,
    required super.caching,
  }) : super(
          type: MusicType.url,
          audioId: const Base64Decoder().convert(remoteAudioUrl).toString(),
        );

  static UrlMusicData<T> fromJson<T extends Caching>({
    required Map<String, dynamic> json,
    required T caching,
  }) {
    return UrlMusicData(
      remoteAudioUrl: json["remoteAudioUrl"] as String,
      remoteImageUrl: json["remoteImageUrl"] as String,
      title: json["title"] as String,
      description: json["description"] as String,
      author: json["author"] as String,
      keywords: (json["keywords"] as List).cast<String>(),
      duration: Duration(milliseconds: json["duration"] as int),
      volume: (json["volume"] as num).toDouble(),
      lyrics: json["lyrics"] as String,
      songStoredAt: json["songStoredAt"] as int?,
      size: json["size"] as int?,
      caching: caching,
    );
  }
}
