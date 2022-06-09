import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/utils/youtube_music_utils.dart';
import 'package:easy_app/easy_app.dart';

class YouTubeMusicData extends MusicData {
  YouTubeMusicData(
      {required this.id,
      required List<String> imageUrls,
      required String title,
      required String description,
      required String author,
      required this.authorId,
      required List<String> keywords,
      required String url,
      required Duration duration,
      required bool isLocal,
      required double volume,
      String? key})
      : super(
            type: MusicType.youtube,
            imageUrls: imageUrls,
            title: title,
            description: description,
            author: author,
            keywords: keywords,
            url: url,
            audioId: id,
            duration: duration,
            isLocal: isLocal,
            volume: volume,
            key: key);

  final String id;
  final String authorId;

  @override
  String get savePath => "${EasyApp.localPath}/music/yt_$id.mp3";

  @override
  String get mediaURL => "https://www.youtube.com/watch?v=$id";

  @override
  Map<String, dynamic> get jsonExtras => {
    'id': id,
    'authorId': authorId,
  };

  @override
  Future<void> refreshURL() async {
    final url = await YouTubeMusicUtils.getAudioURL(id);
    if (url != null) {
      this.url = url;
      remoteUrl = url;
    }
  }

  // from json
  factory YouTubeMusicData.fromJson(Map<String, dynamic> json, {bool local = true}) {
    return YouTubeMusicData(
      id: json['id'] as String,
      url: json['url'] as String,
      imageUrls: (json['imageUrls'] as List).map((e) => e as String).toList(),
      title: json['title'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      authorId: json['authorId'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      isLocal: local,
      keywords: (json['keywords'] as List).map((e) => e as String).toList(),
      volume: json['volume'] as double,
    );
  }
}
