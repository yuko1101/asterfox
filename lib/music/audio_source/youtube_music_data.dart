import 'package:asterfox/system/exceptions/network_exception.dart';
import 'package:easy_app/easy_app.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../system/exceptions/refresh_url_failed_exception.dart';
import '../../utils/youtube_music_utils.dart';
import 'music_data.dart';

class YouTubeMusicData extends MusicData {
  YouTubeMusicData({
    required this.id,
    required String url,
    required String remoteUrl,
    required String imageUrl,
    required String remoteImageUrl,
    required String title,
    required String description,
    required String author,
    required this.authorId,
    required List<String> keywords,
    required Duration duration,
    required bool isLocal,
    required double volume,
    required String key,
    bool isTemporary = false,
  }) : super(
          type: MusicType.youtube,
          url: url,
          remoteUrl: remoteUrl,
          imageUrl: imageUrl,
          remoteImageUrl: remoteImageUrl,
          title: title,
          description: description,
          author: author,
          keywords: keywords,
          audioId: id,
          duration: duration,
          isLocal: isLocal,
          volume: volume,
          key: key,
          isTemporary: isTemporary,
        );

  final String id;
  final String authorId;

  @override
  String get savePath => "${EasyApp.localPath}/music/yt_$id.mp3";

  @override
  String get imageSavePath => "${EasyApp.localPath}/music/yt_$id.png";

  @override
  String get mediaURL => "https://www.youtube.com/watch?v=$id";

  @override
  Map<String, dynamic> get jsonExtras => {
        'id': id,
        'authorId': authorId,
      };

  /// Throws [RefreshUrlFailedException] if failed to refresh the url.
  @override
  Future<String> refreshURL() async {
    try {
      final url = await YouTubeMusicUtils.getAudioURL(id, const Uuid().v4(),
          forceRemote: true);
      remoteUrl = url;
      return url;
    } on NetworkException {
      throw RefreshUrlFailedException();
    } on VideoUnplayableException {
      throw RefreshUrlFailedException();
    }
  }

  final _expiresRegex = RegExp("expires=([0-9]+)");
  @override
  Future<bool> isUrlAvailable() async {
    final expires = _expiresRegex.firstMatch(remoteUrl);
    if (expires != null) {
      final expiresTime = int.parse(expires.group(1)!);
      final now = DateTime.now().millisecondsSinceEpoch;
      // 20秒の余裕を持たせる
      if (expiresTime > now + 20000) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  // from json
  factory YouTubeMusicData.fromJson({
    required Map<String, dynamic> json,
    required bool isLocal,
    required String key,
    bool isTemporary = false,
  }) {
    return YouTubeMusicData(
      key: key,
      id: json['id'] as String,
      url: json['url'] as String,
      remoteUrl: json['remoteUrl'] as String,
      imageUrl: json['imageUrl'] as String,
      remoteImageUrl: json['remoteImageUrl'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      authorId: json['authorId'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      isLocal: isLocal,
      keywords: (json['keywords'] as List).map((e) => e as String).toList(),
      volume: json['volume'] as double,
      isTemporary: isTemporary,
    );
  }
}
