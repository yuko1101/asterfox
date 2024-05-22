import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/local_musics_data.dart';
import '../../system/exceptions/network_exception.dart';
import '../../system/exceptions/refresh_url_failed_exception.dart';
import '../../system/firebase/cloud_firestore.dart';
import '../utils/youtube_music_utils.dart';
import 'music_data.dart';

class YouTubeMusicData extends MusicData {
  YouTubeMusicData({
    required this.id,
    required super.remoteAudioUrl,
    required super.remoteImageUrl,
    required super.title,
    required super.description,
    required super.author,
    required super.keywords,
    required super.duration,
    required super.volume,
    required super.lyrics,
    required super.songStoredAt,
    required super.size,
    required super.key,
    required super.isTemporary,
    required this.authorId,
  }) : super(
          type: MusicType.youtube,
          audioId: id,
        );

  final String id;
  final String authorId;

  @override
  String get mediaURL => "https://www.youtube.com/watch?v=$id";

  @override
  Map<String, dynamic> get jsonExtras => {
        'id': id,
        'authorId': authorId,
      };

  /// Throws [RefreshUrlFailedException] if failed to refresh the url.
  @override
  Future<String> refreshAudioUrl() async {
    print("refreshing youtube audio url...");
    try {
      final url = await YouTubeMusicUtils.getAudioURL(id, const Uuid().v4(),
          forceRemote: true);
      remoteAudioUrl = url;
      await LocalMusicsData.localMusicData
          .get([audioId])
          .set(key: "remoteAudioUrl", value: url)
          .save(compact: LocalMusicsData.compact);
      await CloudFirestoreManager.addOrUpdateSongs([this]);
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
    required String key,
    required bool isTemporary,
  }) {
    return YouTubeMusicData(
      key: key,
      id: json["id"] as String,
      remoteAudioUrl: json["remoteAudioUrl"] as String,
      remoteImageUrl: json["remoteImageUrl"] as String,
      title: json["title"] as String,
      description: json["description"] as String,
      author: json["author"] as String,
      authorId: json["authorId"] as String,
      duration: Duration(milliseconds: json["duration"] as int),
      keywords: (json["keywords"] as List).map((e) => e as String).toList(),
      volume: (json["volume"] as num).toDouble(),
      lyrics: json["lyrics"] as String,
      songStoredAt: json["songStoredAt"] as int?,
      size: json["size"] as int?,
      isTemporary: isTemporary,
    );
  }
}
