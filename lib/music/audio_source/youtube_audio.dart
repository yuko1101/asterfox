import 'package:asterfox/music/audio_source/base/audio_base.dart';

abstract class YouTubeAudio extends AudioBase {
  YouTubeAudio({
    required String url,
    required this.id,
    required String title,
    required String description,
    required String author,
    required this.authorId,
    required bool isLocal
  }) : super(url: url, title: title, description: description, author: author, isLocal: isLocal);
  final String id;
  final String authorId;


}

