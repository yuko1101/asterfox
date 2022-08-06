import 'package:asterfox/data/local_musics_data.dart';
import 'package:easy_app/easy_app.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../system/exceptions/network_exception.dart';
import '../../system/exceptions/refresh_url_failed_exception.dart';
import '../../utils/youtube_music_utils.dart';
import 'music_data.dart';

class YouTubeMusicData extends MusicData {
  YouTubeMusicData({
    required this.id,
    required String remoteUrl,
    required String remoteImageUrl,
    required String title,
    required String description,
    required String author,
    required this.authorId,
    required List<String> keywords,
    required Duration duration,
    required bool isLocal,
    required double volume,
    required String lyrics,
    required String key,
    bool isTemporary = false,
  }) : super(
          type: MusicType.youtube,
          remoteAudioUrl: remoteUrl,
          remoteImageUrl: remoteImageUrl,
          title: title,
          description: description,
          author: author,
          keywords: keywords,
          audioId: id,
          duration: duration,
          isDataStored: isLocal,
          volume: volume,
          lyrics: lyrics,
          key: key,
          isTemporary: isTemporary,
        );

  final String id;
  final String authorId;

  @override
  String get audioSavePath => "${EasyApp.localPath}/music/$id/audio.mp3";

  @override
  String get imageSavePath => "${EasyApp.localPath}/music/$id/image.png";

  @override
  String get mediaURL => "https://www.youtube.com/watch?v=$id";

  @override
  Map<String, dynamic> get jsonExtras => {
        'id': id,
        'authorId': authorId,
      };

  /// Throws [RefreshUrlFailedException] if failed to refresh the url.
  @override
  Future<String> refreshAudioURL() async {
    print("refreshing youtube audio url...");
    try {
      final url = await YouTubeMusicUtils.getAudioURL(id, const Uuid().v4(),
          forceRemote: true);
      remoteAudioUrl = url;
      LocalMusicsData.musicData
          .get([audioId]).set(key: "remoteAudioUrl", value: url);
      await LocalMusicsData.saveData();
      return url;
    } on NetworkException {
      throw RefreshUrlFailedException();
    } on VideoUnplayableException {
      throw RefreshUrlFailedException();
    }
  }

  final _expiresRegex = RegExp("expire=([0-9]+)");
  @override
  Future<bool> isAudioUrlAvailable() async {
    final expires = _expiresRegex.firstMatch(remoteAudioUrl);
    if (expires != null) {
      final expiresTime = int.parse(expires.group(1)!) * 1000;
      final now = DateTime.now().millisecondsSinceEpoch;
      // 1時間の余裕を持たせる
      if (expiresTime > now + 60 * 60 * 1000) {
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
      remoteUrl: json['remoteAudioUrl'] as String,
      remoteImageUrl: json['remoteImageUrl'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      authorId: json['authorId'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      isLocal: isLocal,
      keywords: (json['keywords'] as List).map((e) => e as String).toList(),
      volume: json['volume'] as double,
      lyrics: json['lyrics'] as String,
      isTemporary: isTemporary,
    );
  }
}
