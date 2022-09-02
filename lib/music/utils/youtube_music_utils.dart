import 'dart:async';

import 'package:asterfox/utils/async_utils.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:easy_app/utils/pair.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/local_musics_data.dart';
import '../audio_source/youtube_music_data.dart';
import '../../system/exceptions/network_exception.dart';
import '../../utils/network_check.dart';

class YouTubeMusicUtils {
  /// Throws [NetworkException] if the network is not accessible.
  ///
  /// Throws [VideoUnplayableException] if the video is not playable.
  static Future<String> getAudioURL(String videoId, String key,
      {bool forceRemote = false}) async {
    // 曲が保存されているかどうか
    bool local = LocalMusicsData.isStored(audioId: videoId);
    if (local && !forceRemote) {
      final song = LocalMusicsData.getByAudioId(
          audioId: videoId, key: key, isTemporary: true);
      return song.audioUrl;
    } else {
      // オンライン上から取得

      // インターネット接続確認
      NetworkCheck.check();

      final YoutubeExplode yt = YoutubeExplode();
      StreamManifest manifest;
      try {
        manifest = await yt.videos.streamsClient.getManifest(videoId);
      } on VideoUnplayableException {
        yt.close();
        rethrow;
      }

      // if (manifest.audio.isEmpty && manifest.audioOnly.isEmpty) {
      //   Fluttertoast.showToast(msg: "この曲の音声データが見つかりませんでした");
      //   return null;
      // }

      yt.close();

      return manifest.audioOnly.withHighestBitrate().url.toString();
    }
  }

  /// Throws [NetworkException] if the network is not accessible.
  ///
  /// Throws [VideoUnplayableException] if the video is not playable.
  static Future<YouTubeMusicData> getYouTubeAudio({
    required String videoId,
    required String key,
    required isTemporary,
  }) async {
    // 曲が保存されているかどうか
    bool local = LocalMusicsData.isStored(audioId: videoId);
    if (local) {
      // throws LocalSongNotFoundException
      return LocalMusicsData.getByAudioId(
          audioId: videoId,
          key: key,
          isTemporary: isTemporary) as YouTubeMusicData;
    } else {
      // オンライン上から取得

      // インターネット接続確認
      NetworkCheck.check();

      final YoutubeExplode yt = YoutubeExplode();
      StreamManifest manifest;
      try {
        manifest = await yt.videos.streamsClient.getManifest(videoId);
      } on VideoUnplayableException {
        yt.close();
        rethrow;
      }

      // if (manifest.audio.isEmpty && manifest.audioOnly.isEmpty) {
      //   Fluttertoast.showToast(msg: "この曲の音声データが見つかりませんでした");
      //   return null;
      // }

      final Video video = await yt.videos.get(videoId);

      yt.close();

      return getFromVideo(
          video: video, manifest: manifest, key: key, isTemporary: isTemporary);
    }
  }

  static Map<String, ValueNotifier<int>> playlistLoadingProgress = {};

  /// Returns a pair of the successfully loaded YouTubeMusicData and the loading failed Videos.
  ///
  /// Throws [NetworkException] if the network is not accessible.
  static Future<Pair<List<YouTubeMusicData>, List<Video>>> getPlaylist({
    required String playlistId,
    required bool isTemporary,
    String? processId,
  }) async {
    // インターネット接続確認
    NetworkCheck.check();

    final YoutubeExplode yt = YoutubeExplode();
    // final Playlist playlist = await yt.playlists.get(playlistId);

    final loadFailedVideos = <Video>[];

    final List<Video> videos = await Future.sync(() {
      final completer = Completer<List<Video>>();
      final stream = yt.playlists.getVideos(playlistId);

      final List<Video> result = [];

      stream.listen((video) {
        result.add(video);
      }, onDone: () {
        completer.complete(result);
      });
      return completer.future;
    });

    final result = await _getFromVideos(
        videos: videos, yt: yt, isTemporary: isTemporary, processId: processId);

    yt.close();

    return result;
  }

  static Future<Pair<List<YouTubeMusicData>, List<Video>>> _getFromVideos({
    required List<Video> videos,
    required YoutubeExplode yt,
    required bool isTemporary,
    required String? processId,
  }) async {
    final bool useProgress = processId != null;
    if (useProgress) {
      playlistLoadingProgress[processId] ??= ValueNotifier(0);
    }
    final ValueNotifier<int>? progressNotifier =
        useProgress ? playlistLoadingProgress[processId]! : null;

    final AsyncCore<YouTubeMusicData?> asyncCore = AsyncCore(limit: 20);

    final List<Video> failedToLoad = [];

    final futures = videos.map((video) async {
      final song = await asyncCore.run(() async {
        print("Loading ${videos.indexOf(video)}/${videos.length} (Playlist)");
        return await _getFromVideoWithoutStreamManifest(
          video: video,
          yt: yt,
          key: const Uuid().v4(),
          isTemporary: isTemporary,
        );
      });
      if (song == null) {
        failedToLoad.add(video);
      }
      print(
          "Complete ${videos.indexOf(video)}/${videos.length} (Playlist)${song == null ? " (Unplayable)" : ""}");
      if (useProgress) progressNotifier!.value = progressNotifier.value + 1;
      return song;
    });

    final result = await Future.wait(futures);
    final loaded = result
        .where((element) => element != null)
        .map((e) => e as YouTubeMusicData)
        .toList();

    if (useProgress) playlistLoadingProgress.remove(processId);

    return Pair(loaded, failedToLoad);
  }

  static Future<YouTubeMusicData?> _getFromVideoWithoutStreamManifest({
    required Video video,
    required YoutubeExplode yt,
    required String key,
    required bool isTemporary,
  }) async {
    Future<StreamManifest?> fetch() async {
      try {
        return await yt.videos.streamsClient.getManifest(video.id);
      } on VideoUnplayableException {
        Fluttertoast.showToast(msg: Language.getText("song_unplayable"));
        return null;
      } catch (e) {
        // if (e.toString().)
        print("error: ${e}");
        return null;
      }
    }

    final StreamManifest? manifest = await fetch();
    if (manifest == null) return null;

    return await getFromVideo(
        video: video, manifest: manifest, key: key, isTemporary: isTemporary);
  }

  // even if the song is stored, this fetches it from remote.
  static Future<YouTubeMusicData> getFromVideo({
    required Video video,
    required StreamManifest manifest,
    required String key,
    required bool isTemporary,
  }) async {
    String imageUrl = video.thumbnails.maxResUrl;
    final imageRes = await http.get(Uri.parse(video.thumbnails.maxResUrl));
    if (imageRes.statusCode != 200) {
      imageUrl = video.thumbnails.highResUrl;
    }

    return YouTubeMusicData(
      remoteUrl: manifest.audioOnly.withHighestBitrate().url.toString(),
      id: video.id.value,
      title: video.title,
      description: video.description,
      author: video.author,
      authorId: video.channelId.value,
      duration: video.duration ?? Duration.zero,
      keywords: video.keywords,
      volume: 1.0,
      remoteImageUrl: imageUrl,
      key: key,
      lyrics: "", // TODO: by default, get from closed captions
      songStoredAt: null,
      size: null,
      isTemporary: isTemporary,
    );
  }

  /// Throws [NetworkException] if the network is not accessible.
  static Future<List<Video>> searchYouTubeVideo(String query) async {
    // インターネット接続確認
    NetworkCheck.check();

    final YoutubeExplode yt = YoutubeExplode();
    final results = await yt.search.search(query);
    yt.close();
    return results.toList();
  }

  /// Throws [NetworkException] if the network is not accessible.
  static Future<List<String>> searchWords(String query) async {
    // インターネット接続確認
    NetworkCheck.check();

    final YoutubeExplode yt = YoutubeExplode();
    final results = await yt.search.getQuerySuggestions(query);
    yt.close();
    return results.toList();
  }
}
