import 'dart:convert';

import 'music_data.dart';

class UrlMusicData extends MusicData {
  UrlMusicData({
    required String remoteAudioUrl,
    required String remoteImageUrl,
    required String title,
    required String description,
    required String author,
    required List<String> keywords,
    required Duration duration,
    required double volume,
    required String lyrics,
    required int? songStoredAt,
    required int? size,
    required String key,
    required bool isTemporary,
  }) : super(
          type: MusicType.url,
          remoteAudioUrl: remoteAudioUrl,
          remoteImageUrl: remoteImageUrl,
          title: title,
          description: description,
          author: author,
          keywords: keywords,
          audioId: const Base64Decoder().convert(remoteAudioUrl).toString(),
          duration: duration,
          volume: volume,
          lyrics: lyrics,
          songStoredAt: songStoredAt,
          size: size,
          key: key,
          isTemporary: isTemporary,
        );

  factory UrlMusicData.fromJson({
    required Map<String, dynamic> json,
    required String key,
    required bool isTemporary,
  }) {
    return UrlMusicData(
      key: key,
      remoteAudioUrl: json["remoteAudioUrl"] as String,
      remoteImageUrl: json["remoteImageUrl"] as String,
      title: json["title"] as String,
      description: json["description"] as String,
      author: json["author"] as String,
      keywords: (json["keywords"] as List).map((e) => e as String).toList(),
      duration: Duration(milliseconds: json["duration"] as int),
      volume: (json["volume"] as num).toDouble(),
      lyrics: json["lyrics"] as String,
      songStoredAt: json["songStoredAt"] as int?,
      size: json["size"] as int?,
      isTemporary: isTemporary,
    );
  }
}
