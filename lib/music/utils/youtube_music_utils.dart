import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/local_musics_data.dart';
import '../../system/exceptions/unable_to_load_from_playlist_exception.dart';
import '../music_data/music_data.dart';
import '../music_data/youtube_music_data.dart';
import '../../system/exceptions/network_exception.dart';
import '../../utils/network_utils.dart';

class YouTubeMusicUtils {
  /// Throws [NetworkException] if the network is not accessible.
  ///
  /// Throws [VideoUnplayableException] if the video is not playable.
  static Future<StreamInfo> getStreamInfo(
      String videoId, YoutubeExplode? yt) async {
    NetworkUtils.check();

    return withYT(yt, (yt) async {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      return manifest.audioOnly.withHighestBitrate();
    });
  }

  /// Throws [NetworkException] if the network is not accessible.
  ///
  /// Throws [VideoUnplayableException] if the video is not playable.
  static Future<YouTubeMusicData<T>> getYouTubeMusicData<T extends Caching>({
    required Video video,
    required YoutubeExplode? yt,
    required T caching,
  }) async {
    final videoId = video.id.value;
    bool local = LocalMusicsData.isStored(audioId: videoId);
    if (local) {
      // throws LocalSongNotFoundException
      return LocalMusicsData.getByAudioId(
        audioId: videoId,
        caching: caching,
      ) as YouTubeMusicData<T>;
    } else {
      NetworkUtils.check();

      final streamInfo = await getStreamInfo(videoId, yt);

      return getFromVideo(
        video: video,
        streamInfo: streamInfo,
        caching: caching,
      );
    }
  }

  static Map<String, ValueNotifier<int>> playlistLoadingProgress = {};

  /// Returns a pair of the successfully loaded YouTubeMusicData and the loading failed Videos.
  ///
  /// Throws [NetworkException] if the network is not accessible.
  static Stream<YouTubeMusicData>
      $getMusicDataFromPlaylist({
    required String playlistId,
    required bool caching,
    required YoutubeExplode? yt,
  }) {
    NetworkUtils.check();

    final ytContainer = YTContainer(yt);

    final controller = StreamController<YouTubeMusicData>();
    final videoStream = ytContainer.get().playlists.getVideos(playlistId);

    int processingCount = 0;
    bool done = false;

    void close() {
      controller.sink.close();
      ytContainer.close();
    }

    videoStream.listen((video) async {
      processingCount++;
      try {
        final musicData = await _getFromVideoWithoutStreamInfo(
          video: video,
          yt: ytContainer.get(),
          caching: caching ? CachingEnabled(const Uuid().v4()) : CachingDisabled(),
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

  static Stream<YouTubeMusicData<CachingEnabled>> getMusicDataFromPlaylistWithCaching({
    required String playlistId,
    required YoutubeExplode? yt,
  }) =>
      $getMusicDataFromPlaylist(
        playlistId: playlistId,
        caching: true,
        yt: yt,
      ) as Stream<YouTubeMusicData<CachingEnabled>>;

  static Stream<YouTubeMusicData<CachingDisabled>> getMusicDataFromPlaylistWithoutCaching({
    required String playlistId,
    required YoutubeExplode? yt,
  }) =>
      $getMusicDataFromPlaylist(
        playlistId: playlistId,
        caching: false,
        yt: yt,
      ) as Stream<YouTubeMusicData<CachingDisabled>>;

  static Future<YouTubeMusicData<T>>
      _getFromVideoWithoutStreamInfo<T extends Caching>({
    required Video video,
    required YoutubeExplode? yt,
    required T caching,
  }) async {
    if (LocalMusicsData.isStored(audioId: video.id.value)) {
      final song = LocalMusicsData.getByAudioId(
        audioId: video.id.value,
        caching: caching,
      ) as YouTubeMusicData<T>;
      if (!await song.isAudioUrlAvailable()) await song.refreshAudioUrl();
      return song;
    }

    final streamInfo = await getStreamInfo(video.id.value, yt);

    return await getFromVideo(
      video: video,
      streamInfo: streamInfo,
      caching: caching,
    );
  }

  // even if the song is stored, this fetches it from remote.
  static Future<YouTubeMusicData<T>> getFromVideo<T extends Caching>({
    required Video video,
    required StreamInfo streamInfo,
    required T caching,
  }) async {
    String imageUrl = video.thumbnails.maxResUrl;
    final imageRes = await http.get(Uri.parse(video.thumbnails.maxResUrl));
    if (imageRes.statusCode != 200) {
      imageUrl = video.thumbnails.highResUrl;
    }

    return YouTubeMusicData(
      id: video.id.value,
      title: video.title,
      description: video.description,
      author: video.author,
      authorId: video.channelId.value,
      duration: video.duration ?? Duration.zero,
      keywords: video.keywords,
      volume: 1.0,
      remoteImageUrl: imageUrl,
      lyrics: "", // TODO: by default, get from closed captions
      songStoredAt: null,
      size: null,
      caching: caching,
      streamInfo: streamInfo,
    );
  }

  /// Throws [NetworkException] if the network is not accessible.
  static Future<List<Video>> searchYouTubeVideo(
    String query,
    YoutubeExplode? yt,
  ) async {
    NetworkUtils.check();

    return withYT(yt, (yt) async {
      final results = await yt.search.search(query);
      return results.toList();
    });
  }

  /// Throws [NetworkException] if the network is not accessible.
  static Future<List<String>> searchWords(
    String query,
    YoutubeExplode? yt,
  ) async {
    NetworkUtils.check();

    return withYT(yt, (yt) async {
      final results = await yt.search.getQuerySuggestions(query);
      return results.toList();
    });
  }

  static T withYT<T>(YoutubeExplode? yt, T Function(YoutubeExplode yt) f) {
    if (yt == null) {
      final temp = YoutubeExplode();
      final result = f(temp);
      temp.close();
      return result;
    } else {
      return f(yt);
    }
  }
}

class YTContainer {
  final YoutubeExplode? yt;
  late final YoutubeExplode? tempYT;
  late final bool isTemp;

  YTContainer(this.yt) {
    if (yt == null) {
      tempYT = YoutubeExplode();
      isTemp = true;
    } else {
      isTemp = false;
    }
  }

  YoutubeExplode get() => yt ?? tempYT!;

  void close() {
    tempYT?.close();
  }
}

extension MusicDataUtil on Video {
  Future<YouTubeMusicData<T>> fetchMusicData<T extends Caching>({
    required T caching,
    required YoutubeExplode? yt,
  }) =>
      YouTubeMusicUtils.getYouTubeMusicData(
        yt: yt,
        video: this,
        caching: caching,
      );
}
