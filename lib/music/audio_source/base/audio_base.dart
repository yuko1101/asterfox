import 'dart:io';

import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/youtube_audio.dart';
import 'package:audio_service/audio_service.dart';
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
    required this.keywords,
    required this.volume,
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
  final List<String> keywords;
  double volume;
  String? key;

  static String classId() => "audio";

  MediaItem getMediaItem() {
    return MediaItem(
      id: key!,
      title: title,
      duration: Duration(milliseconds: duration),
      artist: author,
      extras: toMap(),
    );
  }

  void setVolume(double volume) {
    this.volume = volume;
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
      'keywords': keywords,
      'volume': volume,
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
      keywords: (json['keywords'] as List).map((e) => e as String).toList(),
      volume: json['volume'] as double,
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
      'keywords': keywords,
      'volume': volume,
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
      isLocal: json['isLocal'] as bool,
      keywords: (json['keywords'] as List).map((e) => e as String).toList(),
      volume: json['volume'] as double,
    );
  }

  AudioBase copyAsLocal() {
    final newKey = const Uuid().v4();
    return AudioBase(
      url: '$localPath${Platform.pathSeparator}base-$newKey.mp3',
      imageUrl: imageUrl,
      title: title,
      description: description,
      author: author,
      duration: duration,
      isLocal: true,
      keywords: keywords,
      volume: volume,
      key: newKey,
    );
  }

  Future<AudioBase> refresh() async {
    final newKey = const Uuid().v4();
    return AudioBase(
      url: url,
      imageUrl: imageUrl,
      title: title,
      description: description,
      author: author,
      duration: duration,
      isLocal: isLocal,
      keywords: keywords,
      volume: volume,
      key: newKey,
    );
  }
}


extension AudioSourceParseMusicData on IndexedAudioSource {
  AudioBase asAudioBase() {
    if (tag is AudioBase) return tag as AudioBase;
    if (tag is MediaItem) {
      final mediaItem = tag as MediaItem;
      if (mediaItem.extras != null) {
        return parse(mediaItem.extras!);
      }
    }
    return parse(tag);
  }
}

extension MediaItemParseMusicData on MediaItem {
  AudioBase asAudioBase() {
    if (extras != null) {
      return parse(extras!);
    }
    throw Exception('MediaItem has no extras');
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