import 'package:asterfox/music/audio_source/base/audio_base.dart';

class MediaAudio extends AudioBase {
  MediaAudio({
    required String url,
    required String imageUrl,
    required String title,
    required String description,
    required String author,
    required int duration,
    required bool isLocal
  }) : super(url: url, imageUrl: imageUrl, title: title, description: description, author: author, duration: duration, isLocal: isLocal);

  String getMediaURL() {
    return url;
  }

  @override
  String classId() => "media";

}