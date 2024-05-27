import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/song_history_data.dart';
import '../../main.dart';
import '../utils/music_url_utils.dart';
import '../utils/youtube_music_utils.dart';
import 'url_music_data.dart';
import 'youtube_music_data.dart';
import '../../data/local_musics_data.dart';

class MusicData<T extends Caching> {
  MusicData({
    required this.type,
    required this.remoteAudioUrl,
    required this.remoteImageUrl,
    required this.title,
    required this.description,
    required this.author,
    required this.keywords,
    required this.audioId,
    required this.duration,
    required this.volume,
    required this.lyrics,
    required this.songStoredAt,
    required this.size,
    required this.key,
    required this.caching,
  }) {
    print("MusicData created : caching = $caching");
    if (!caching.enabled) return;
    print("MusicData: {key: $key, title: $title}");
    _created[key] = this as MusicData<CachingEnabled>;
  }
  final MusicType type;
  final String title;
  final String description;
  final String author;
  final List<String> keywords;
  final String audioId;
  Duration duration; // can be changed on clip-cut.
  double volume; // can be changed on volume change.
  String lyrics;
  int? songStoredAt;
  int? size; // file size in Bytes
  final String key;
  String remoteAudioUrl;
  String remoteImageUrl;

  final T caching;

  Future<MediaItem> toMediaItem() async {
    return toMediaItemWithUrl(await audioUrl);
  }

  MediaItem toMediaItemWithUrl(String url) {
    return MediaItem(
      id: key,
      title: title,
      artist: author,
      artUri: Uri.parse(isInstalled ? "file://$imageSavePath" : remoteImageUrl),
      duration: duration,
      displayDescription: description,
      extras: {
        "url": url,
      },
    );
  }

  String get mediaURL => remoteAudioUrl;

  String get directoryPath => getDirectoryPath(audioId);
  String get audioSavePath => getAudioSavePath(audioId);
  String get imageSavePath => getImageSavePath(audioId);
  String get installCompleteFilePath => getInstallCompleteFilePath(audioId);

  void destroy() {
    _created.remove(key);
    print("MusicData destroyed : remaining = ${_created.length}");
  }

  static MusicData? fromKey(String key) {
    return _created[key];
  }

  Map<String, dynamic> toJson() {
    final json = {
      "type": type.name,
      "remoteAudioUrl": remoteAudioUrl,
      "remoteImageUrl": remoteImageUrl,
      "title": title,
      "description": description,
      "author": author,
      "audioId": audioId,
      "duration": duration.inMilliseconds,
      "keywords": keywords,
      "volume": volume,
      "lyrics": lyrics,
      "songStoredAt": songStoredAt,
      "size": size,
    };
    jsonExtras.forEach((key, value) {
      json[key] = value;
    });
    return json;
  }

  Map<String, dynamic> get jsonExtras => {};

  static MusicData<T> fromJson<T extends Caching>({
    required Map<String, dynamic> json,
    required String key,
    required T caching,
  }) {
    final type = MusicType.values
        .firstWhere((musicType) => musicType.name == json["type"] as String);
    switch (type) {
      case MusicType.youtube:
        return YouTubeMusicData.fromJson(
          json: json,
          key: key,
          caching: caching,
        );
      case MusicType.url:
        return UrlMusicData.fromJson(
          json: json,
          key: key,
          caching: caching,
        );
      // default:
      //   return MusicData(
      //     key: key,
      //     type: type,
      //     remoteAudioUrl: json["remoteAudioUrl"] as String,
      //     remoteImageUrl: json["remoteImageUrl"] as String,
      //     title: json["title"] as String,
      //     description: json["description"] as String,
      //     author: json["author"] as String,
      //     audioId: json["audioId"] as String,
      //     duration: Duration(milliseconds: json["duration"] as int),
      //     isDataStored: isLocal,
      //     keywords: (json["keywords"] as List).map((e) => e as String).toList(),
      //     volume: json["volume"] as double,
      //     lyrics: json["lyrics"] as String,
      //     caching: caching,
      //   );
    }
  }

  Future<String> refreshAudioUrl() async {
    return remoteAudioUrl;
  }

  Future<bool> isAudioUrlAvailable() async {
    return true;
  }

  Future<String> getAvailableAudioUrl() async {
    if (await isAudioUrlAvailable()) return remoteAudioUrl;
    return await refreshAudioUrl();
  }

  static String getDirectoryPath(String audioId) =>
      "$localPath/music/$audioId".replaceAll("/", Platform.pathSeparator);
  static String getAudioSavePath(String audioId) =>
      "${getDirectoryPath(audioId)}/audio.mp3"
          .replaceAll("/", Platform.pathSeparator);
  static String getImageSavePath(String audioId) =>
      "${getDirectoryPath(audioId)}/image.png"
          .replaceAll("/", Platform.pathSeparator);
  static String getInstallCompleteFilePath(String audioId) =>
      "${getDirectoryPath(audioId)}/installed.txt"
          .replaceAll("/", Platform.pathSeparator);

  static final Map<String, MusicData<CachingEnabled>> _created = {};
  static Map<String, MusicData> getCreated() {
    return _created;
  }

  static void clearCreated() {
    _created.clear();
  }

  static void deleteCreated(String key) {
    _created.remove(key);
  }

  /// Throws [VideoUnplayableException], [NetworkException]
  static Future<MusicData<T>> getByAudioId<T extends Caching>({
    required String audioId,
    required String key,
    required T caching,
  }) async {
    return await YouTubeMusicUtils.getYouTubeAudio(
      videoId: audioId,
      key: key,
      caching: caching,
    );
  }

  static Future<MusicData<T>> get<T extends Caching>({
    String? audioId,
    String? mediaUrl,
    MusicData? musicData,
    required String key,
    required T caching,
  }) async {
    assert(audioId != null || mediaUrl != null || musicData != null);

    if (musicData != null) {
      return musicData.renew(key: key, caching: caching);
    }

    final id = audioId ?? MusicUrlUtils.getAudioIdFromUrl(mediaUrl!);

    return await getByAudioId(audioId: id, key: key, caching: caching);
  }

  /// if renew is false, musicData in musicDataList won't be renewed by MusicData#renew().
  static Stream<MusicData<T>> getList<T extends Caching>({
    List<MusicData>? musicDataList,
    List<String>? mediaUrlList,
    String? youtubePlaylist,
    required T caching,
  }) {
    final controller = StreamController<MusicData<T>>();

    int remaining = (musicDataList?.length ?? 0) + (mediaUrlList?.length ?? 0);
    bool isYouTubePlaylistDone = youtubePlaylist == null;

    if (remaining == 0 && isYouTubePlaylistDone) {
      controller.sink.close();
    }

    void add(MusicData<T> event) {
      controller.sink.add(event);
      remaining--;
      if (remaining == 0 && isYouTubePlaylistDone) {
        controller.sink.close();
      }
    }

    if (musicDataList != null) {
      for (final musicData in musicDataList) {
        add(
          musicData.renew(
            key: const Uuid().v4(),
            caching: caching,
          ),
        );
      }
    }
    if (mediaUrlList != null) {
      for (final mediaUrl in mediaUrlList) {
        MusicData.get(
          mediaUrl: mediaUrl,
          key: const Uuid().v4(),
          caching: caching,
        ).then(add);
      }
    }
    if (youtubePlaylist != null) {
      final playlistStream = YouTubeMusicUtils.getMusicDataFromPlaylist(
        playlistId: youtubePlaylist,
        caching: caching,
      );

      playlistStream.listen(
        controller.sink.add,
        onError: (e) {
          controller.sink.addError(e);
        },
        onDone: () {
          if (remaining > 0) {
            isYouTubePlaylistDone = true;
          } else {
            controller.sink.close();
          }
        },
      );
    }

    return controller.stream;
  }
}

enum MusicType { youtube, url }

extension MediaItemParseMusicData on MediaItem {
  MusicData toMusicData() {
    return MusicData.fromKey(id)!;
  }
}

extension AudioSourceParseMusicData on IndexedAudioSource {
  MusicData toMusicData() {
    return MusicData.fromKey(tag["key"])!;
  }
}

class Caching {
  // whether to cache the instance into the `created`.
  bool get enabled => this is CachingEnabled;
}

class CachingEnabled extends Caching {}

class CachingDisabled extends Caching {}
