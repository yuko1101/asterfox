import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/youtube_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';

class AudioBase {
  AudioBase({
    required this.url,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.author,
    required this.duration,
    required this.isLocal,
    this.key

  }) {
    key ??= const Uuid().v4();
  }

  final String url;
  final String imageUrl;
  final String title;
  final String description;
  final String author;
  final int duration;
  bool isLocal;
  String? key;

  static String classId() => "audio";

  MediaItem getMediaItem() {
    return MediaItem(
        id: key!,
        title: title,
        // duration: Duration(milliseconds: duration),
        extras: {
          "tag": toMap(),
          "url": url
        }
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': classId(),
      'url': url,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'author': author,
      'duration': duration,
      'isLocal': isLocal,
    };
  }

  factory AudioBase.fromJson(Map<String, dynamic> json, bool local) {
    return AudioBase(
      url: json['url'] as String,
      imageUrl: json['imageUrl'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      duration: json['duration'] as int,
      isLocal: local,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'type': classId(),
      'url': url,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'author': author,
      'duration': duration,
      'isLocal': isLocal,
      'key': key,
    };
  }

  factory AudioBase.fromMap(Map<String, dynamic> json) {
    return AudioBase(
      url: json['url'] as String,
      imageUrl: json['imageUrl'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      duration: json['duration'] as int,
      isLocal: json['isLocal'] as bool
    );
  }

  AudioBase copyAsLocal() {
    final newKey = const Uuid().v4();
    return AudioBase(
      url: '$localPath/base-$newKey.mp3',
      imageUrl: imageUrl,
      title: title,
      description: description,
      author: author,
      duration: duration,
      isLocal: true,
      key: newKey,
    );
  }
}

extension ParseMusicData on MediaItem {
  AudioBase asMusicData() {
    return parse(extras!["tag"]);
  }
}

extension AudioSourceParseMusicData on IndexedAudioSource {
  AudioBase asMusicData() {
    if (tag is AudioBase) return tag as AudioBase;
    return parse(tag);
  }
}

AudioBase parse(Map<String, dynamic> tag) {
  final String type = tag["type"];
  switch (type) {
    case "youtube": return YouTubeAudio.fromMap(tag);
  }
  return AudioBase.fromMap(tag);
}


AudioBase loadFromJson(Map<String, dynamic> json, {bool local = true}) {
  final String type = json["type"];
  switch (type) {
    case "youtube": return YouTubeAudio.fromJson(json, local: local);
  }
  return AudioBase.fromJson(json, local);
}