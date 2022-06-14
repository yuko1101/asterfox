import 'dart:async';
import 'dart:io';

import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/youtube_music_data.dart';
import 'package:asterfox/utils/logger.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:easy_app/utils/network_utils.dart';
import 'package:easy_app/utils/pair.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

class YouTubeMusicUtils {
  static Future<String?> getAudioURL(String videoId, String key, {bool forceRemote = false}) async {
    // 曲が保存されているかどうか
    bool local = LocalMusicsData.isSaved(audioId: videoId);
    if (local && !forceRemote) {
      final song = LocalMusicsData.getByAudioId(audioId: videoId, key: key, isTemporary: true)!;
      return song.url;
    } else {
      // オンライン上から取得

      // インターネット接続確認
      if (!NetworkUtils.networkAccessible()) {
        NetworkUtils.showNetworkAccessDeniedMessage();
        return null;
      }

      final YoutubeExplode yt = YoutubeExplode();
      StreamManifest manifest;
      try {
        manifest = await yt.videos.streamsClient.getManifest(videoId);
      } on VideoUnplayableException {
        Fluttertoast.showToast(msg: Language.getText("song_unplayable"));
        yt.close();
        return null;
      }

      // if (manifest.audio.isEmpty && manifest.audioOnly.isEmpty) {
      //   Fluttertoast.showToast(msg: "この曲の音声データが見つかりませんでした");
      //   return null;
      // }

      yt.close();

      return manifest.audioOnly.withHighestBitrate().url.toString();

    }
  }

  static Future<YouTubeMusicData?> getYouTubeAudio({
    required String videoId,
    required String key,
    bool isTemporary = false,
  }) async {
    // 曲が保存されているかどうか
    bool local = LocalMusicsData.isSaved(audioId: videoId);
    if (local) {
      return LocalMusicsData.getByAudioId(audioId: videoId, key: key) as YouTubeMusicData?;
    } else {
      // オンライン上から取得

      // インターネット接続確認
      if (!NetworkUtils.networkAccessible()) {
        NetworkUtils.showNetworkAccessDeniedMessage(
          notAccessibleMessage: Language.getText("network_not_accessible"),
          notConnectedMessage: Language.getText("network_not_connected")
        );
        return null;
      }

      final YoutubeExplode yt = YoutubeExplode();
      StreamManifest manifest;
      try {
        manifest = await yt.videos.streamsClient.getManifest(videoId);
      } on VideoUnplayableException {
        Fluttertoast.showToast(msg: Language.getText("song_unplayable"));
        yt.close();
        return null;
      }

      // if (manifest.audio.isEmpty && manifest.audioOnly.isEmpty) {
      //   Fluttertoast.showToast(msg: "この曲の音声データが見つかりませんでした");
      //   return null;
      // }

      final Video video = await yt.videos.get(videoId);


      yt.close();

      return getFromVideo(
          video: video,
          manifest: manifest,
          key: key,
          isTemporary: isTemporary
      );

    }
  }

  /// Returns a pair of the successfully loaded YouTubeMusicData and the loading failed Videos.
  static Future<Pair<List<YouTubeMusicData>, List<Video>>> getPlaylist({
    required String playlistId,
    bool isTemporary = false,
  }) async {
    // インターネット接続確認
    if (!NetworkUtils.networkAccessible()) {
      NetworkUtils.showNetworkAccessDeniedMessage(
          notAccessibleMessage: Language.getText("network_not_accessible"),
          notConnectedMessage: Language.getText("network_not_connected")
      );
      return Pair([], []);
    }

    final YoutubeExplode yt = YoutubeExplode();
    // final Playlist playlist = await yt.playlists.get(playlistId);
    final List<Video> videos = await Future.sync(() {
      final completer = Completer<List<Video>>();
      final stream = yt.playlists.getVideos(playlistId);
      final result = <Video>[];
      stream.listen((event) {
        result.add(event);
      }, onDone: () {
        completer.complete(result);
      });
      return completer.future;
    });

    final unloadedVideos = <Video>[];

    final List<Future<YouTubeMusicData?>> parsers = videos.map((video) async {
      StreamManifest manifest;
      try {
        manifest = await yt.videos.streamsClient.getManifest(video.id);
      } on VideoUnplayableException {
        Fluttertoast.showToast(msg: Language.getText("song_unplayable"));
        unloadedVideos.add(video);
        return null;
      }
      return getFromVideo(
          video: video,
          key: const Uuid().v4(),
          manifest: manifest,
          isTemporary: isTemporary
      );
    }).toList();

    final List<YouTubeMusicData> loadedVideos = (await Future.wait(parsers)).where((element) => element != null).map((e) => e as YouTubeMusicData).toList();

    yt.close();

    return Pair(loadedVideos, unloadedVideos);

  }

  static Future<YouTubeMusicData> getFromVideo({
    required Video video,
    required StreamManifest manifest,
    required String key,
    bool isTemporary = false,
  }) async {
    String imageUrl = video.thumbnails.maxResUrl;
    final imageRes = await http.get(Uri.parse(video.thumbnails.maxResUrl));
    if (imageRes.statusCode != 200) {
      imageUrl = video.thumbnails.highResUrl;
    }

    return YouTubeMusicData(
      url: manifest.audioOnly.withHighestBitrate().url.toString(),
      remoteUrl: manifest.audioOnly.withHighestBitrate().url.toString(),
      id: video.id.value,
      title: video.title,
      description: video.description,
      author: video.author,
      authorId: video.channelId.value,
      duration: video.duration ?? Duration.zero,
      isLocal: false,
      keywords: video.keywords,
      volume: 1.0,
      imageUrl: imageUrl,
      remoteImageUrl: imageUrl,
      key: key,
      isTemporary: isTemporary,
    );
  }

  static Future<List<Video>> searchYouTubeVideo(String query) async {
    final YoutubeExplode yt = YoutubeExplode();
    final results = await yt.search.search(query);
    yt.close();
    return results.toList();
  }

  static Future<List<String>> searchWords(String query) async {
    final YoutubeExplode yt = YoutubeExplode();
    final results = await yt.search.getQuerySuggestions(query);
    yt.close();
    return results.toList();
  }
}
