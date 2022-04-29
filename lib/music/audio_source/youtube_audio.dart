import 'package:asterfox/music/audio_source/base/media_audio.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart';

class YouTubeAudio extends MediaAudio {
  YouTubeAudio({
    required String url,
    required this.id,
    required String title,
    required String description,
    required String author,
    required this.authorId,
    required int duration,
    required bool isLocal,
    required List<String> keywords,
    String? key
  }) : super(url: url, imageUrl: isLocal ? "$localPath/images/$id.png" : "https://img.youtube.com/vi/$id/maxresdefault.jpg", title: title, description: description, author: author, duration: duration, isLocal: isLocal, keywords: keywords, key: key);
  final String id;
  final String authorId;


  @override
  String getMediaURL() {
    return "https://www.youtube.com/watch?v=$id";
  }

  static String classId() => "youtube";

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': classId(),
      'url': url,
      'title': title,
      'description': description,
      'author': author,
      'authorId': authorId,
      'duration': duration,
      'id': id,
      'keywords': keywords,
    };
  }

  // from json
  factory YouTubeAudio.fromJson(Map<String, dynamic> json, {bool local = true}) {
    return YouTubeAudio(
      url: json['url'] as String,
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      author: '',
      authorId: '',
      duration: json['duration'] as int,
      isLocal: local,
      keywords: (json['keywords'] as List).map((e) => e as String).toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': classId(),
      'url': url,
      'title': title,
      'description': description,
      'author': author,
      'authorId': authorId,
      'duration': duration,
      'isLocal': isLocal,
      'id': id,
      'keywords': keywords,
      'key': key
    };
  }

  factory YouTubeAudio.fromMap(Map<String, dynamic> json) {
    return YouTubeAudio(
        url: json['url'] as String,
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        author: json['author'] as String,
        authorId: json['authorId'] as String,
        duration: json['duration'] as int,
        isLocal: json['isLocal'] as bool,
        keywords: (json['keywords'] as List).map((e) => e as String).toList(),
        key: json['key'] as String?
    );
  }

  @override
  YouTubeAudio copyAsLocal() {
    return YouTubeAudio(
      url: '$localPath/music/yt-$id.mp3',
      id: id,
      title: title,
      description: description,
      author: author,
      authorId: authorId,
      duration: duration,
      isLocal: true,
      keywords: keywords,
      key: const Uuid().v4()
    );

  }
}

