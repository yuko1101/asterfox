import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/local_musics_data.dart';
import '../../system/exceptions/unable_to_load_from_playlist_exception.dart';
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
  static Stream<YouTubeMusicData> getMusicDataFromPlaylist({
    required String playlistId,
    required bool isTemporary,
  }) {
    // インターネット接続確認
    NetworkCheck.check();

    final controller = StreamController<YouTubeMusicData>();
    final YoutubeExplode yt = YoutubeExplode();
    final videoStream = yt.playlists.getVideos(playlistId);

    int processingCount = 0;
    bool done = false;

    void close() {
      controller.sink.close();
      yt.close();
    }

    videoStream.listen((video) async {
      processingCount++;
      try {
        final musicData = await _getFromVideoWithoutStreamManifest(
          video: video,
          yt: yt,
          key: const Uuid().v4(),
          isTemporary: isTemporary,
        );
        controller.sink.add(musicData);
      } catch (e, stacktrace) {
        controller.sink.addError(
          UnableToLoadFromPlaylistException(video: video, cause: e),
          stacktrace,
        );
      }
      processingCount--;
      if (processingCount == 0 && done) {
        close();
      }
    }, onDone: () {
      if (processingCount > 0) {
        done = true;
      } else {
        close();
      }
    });

    return controller.stream;
  }

  static Future<YouTubeMusicData> _getFromVideoWithoutStreamManifest({
    required Video video,
    required YoutubeExplode yt,
    required String key,
    required bool isTemporary,
  }) async {
    if (LocalMusicsData.isStored(audioId: video.id.value)) {
      final song = LocalMusicsData.getByAudioId(
        audioId: video.id.value,
        key: key,
        isTemporary: isTemporary,
      ) as YouTubeMusicData;
      if (!(await song.isAudioUrlAvailable())) await song.refreshAudioUrl();
      return song;
    }

    final StreamManifest manifest =
        await yt.videos.streamsClient.getManifest(video.id);

    return await getFromVideo(
      video: video,
      manifest: manifest,
      key: key,
      isTemporary: isTemporary,
    );
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
      remoteAudioUrl: manifest.audioOnly.withHighestBitrate().url.toString(),
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
