import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:uuid/uuid.dart';

import '../../../main.dart';

class MediaAudio extends AudioBase {
  MediaAudio({
    required String url,
    required String imageUrl,
    required String title,
    required String description,
    required String author,
    required int duration,
    required bool isLocal, String? key
  }) : super(url: url, imageUrl: imageUrl, title: title, description: description, author: author, duration: duration, isLocal: isLocal, key: key);

  String getMediaURL() {
    return url;
  }

  static String classId() => "media";

  @override
  MediaAudio copyAsLocal() {
    final newKey = const Uuid().v4();
    return MediaAudio(
      url: '$localPath/media-$newKey.mp3',
      imageUrl: imageUrl,
      title: title,
      description: description,
      author: author,
      duration: duration,
      isLocal: true,
      key: newKey
    );
  }
}