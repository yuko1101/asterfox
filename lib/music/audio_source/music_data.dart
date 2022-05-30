import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/youtube_music_data.dart';
import 'package:asterfox/music/music_downloader.dart';
import 'package:asterfox/util/network_util.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class MusicData {
  MusicData({
    required this.type,
    required this.imageUrls,
    required this.title,
    required this.description,
    required this.author,
    required this.keywords,
    required this.url,
    required this.audioId,
    required this.duration,
    required this.isLocal,
    required this.volume,
  }) {
    key = const Uuid().v4();
    _created.add(this);
}
  final MusicType type;
  List<String> imageUrls; // can be changed on save to local. The reason this is a list is because sometimes images are not available. Load the first image if it is available.
  final String title;
  final String description;
  final String author;
  final List<String> keywords;
  String url; // can be changed if the url is expired (especially for YouTube), or the song saved locally.
  late String audioId;
  Duration duration; // can be changed on clip-cut
  bool isLocal; // can be changed on save to local
  double volume; // can be changed on volume change
  late String key;


  MediaItem toMediaItem() {
    return MediaItem(
      id: key,
      title: title,
      artist: author,
      duration: duration,
      displayDescription: description,
      extras: {
        "url": url,
      }
    );
  }

  String get mediaURL => url;

  String get savePath => "$localPath/music/$key.mp3";

  void destroy() {
    _created.remove(this);
  }

  factory MusicData.fromKey(String key) {
    return _created.firstWhere((element) => element.key == key);
  }

   Map<String, dynamic> toJson() {
    final json = {
      'type': type.name,
      'url': savePath,
      'imageUrls': imageUrls,
      'title': title,
      'description': description,
      'author': author,
      'audioId': audioId,
      'duration': duration.inMilliseconds,
      'keywords': keywords,
      'volume': volume,
    };
    jsonExtras.forEach((key, value) {
      json[key] = value;
    });
    return json;
  }

  Map<String, dynamic> get jsonExtras => {};

  factory MusicData.fromJson(Map<String, dynamic> json, bool local) {
    final type = MusicType.values.firstWhere((musicType) => musicType.name == json['type'] as String);
    switch (type) {
      case MusicType.youtube:
        return YouTubeMusicData.fromJson(json, local: local);
      default:
        return MusicData(
          type: type,
          url: json['url'] as String,
          imageUrls: (json['imageUrls'] as List).map((e) => e as String).toList(),
          title: json['title'] as String,
          description: json['description'] as String,
          author: json['author'] as String,
          audioId: json['audioId'] as String,
          duration: Duration(milliseconds: json['duration'] as int),
          isLocal: local,
          keywords: (json['keywords'] as List).map((e) => e as String).toList(),
          volume: json['volume'] as double,
        );
    }
  }

  Future<void> save() async {
    await MusicDownloader.download(this);
  }

  final _httpRegex = RegExp(r'^https?:\/\/.+$');
  Future<Map<String, dynamic>?> getAvailableImage() async {
    for (final imageUrl in imageUrls) {
      if (!NetworkUtils.networkAccessible() && _httpRegex.hasMatch(imageUrl)) continue;
      if (!_httpRegex.hasMatch(imageUrl)) {
        return {'url': imageUrl};
      }
      final imageRes = await http.get(Uri.parse(imageUrl));
      if (imageRes.statusCode == 200) {
        return {"url": imageUrl, "response": imageRes};
      }
    }
    return null;
  }
}


List<MusicData> _created = [];

enum MusicType {
  youtube,
  custom
}

extension MusicTypeExtension on MusicType {
  String get name {
    switch (this) {
      case MusicType.youtube:
        return "youtube";
      case MusicType.custom:
        return "custom";
    }
  }
}


extension MediaItemParseMusicData on MediaItem {
  MusicData toMusicData() {
    return _created.firstWhere((musicData) => musicData.key == id);
  }
}

extension AudioSourceParseMusicData on IndexedAudioSource {
  MusicData toMusicData() {
    return _created.firstWhere((musicData) => musicData.key == tag["key"]);
  }
}