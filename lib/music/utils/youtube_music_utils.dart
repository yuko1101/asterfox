import 'dart:async';

import 'package:http/http.dart' as http;
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
    if (LocalMusicsData.isStored(audioId: videoId)) {
      return LocalMusicsData.getByAudioId(
        audioId: videoId,
        caching: caching,
      ) as YouTubeMusicData<T>;
    }

    final streamInfo = await getStreamInfo(videoId, yt);
    return getFromVideo(
      video: video,
      streamInfo: streamInfo,
      caching: caching,
    );
  }

  /// The songs of the playlist [playlistId]. A video that could not be loaded
  /// is reported as an [UnableToLoadFromPlaylistException] error, and the
  /// stream goes on with the others.
  ///
  /// Throws [NetworkException] if the network is not accessible.
  static Stream<YouTubeMusicData<T>>
      getMusicDataFromPlaylist<T extends Caching>({
    required String playlistId,
    required T caching,
    required YoutubeExplode? yt,
  }) {
    NetworkUtils.check();

    final client = yt ?? YoutubeExplode();
    final controller = StreamController<YouTubeMusicData<T>>();

    // Every video is loaded as soon as it is listed. The stream ends once the
    // listing has ended (or failed) and the last of them has been loaded.
    final loads = <Future<void>>[];
    Future<void> load(Video video) async {
      try {
        controller.add(await _getFromVideoWithoutStreamInfo(
          video: video,
          yt: client,
          // Each song of the playlist is a song of its own in the queue.
          caching: caching.unique(),
        ));
      } catch (e, stacktrace) {
        controller.addError(
          UnableToLoadFromPlaylistException(video: video, cause: e),
          stacktrace,
        );
      }
    }

    Future<void> finish() async {
      await Future.wait(loads);
      if (yt == null) client.close();
      await controller.close();
    }

    client.playlists.getVideos(playlistId).listen(
      (video) => loads.add(load(video)),
      onError: (Object e, StackTrace stacktrace) {
        controller.addError(e, stacktrace);
        finish();
      },
      onDone: finish,
      cancelOnError: true,
    );

    return controller.stream;
  }

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
    // Not every video has a max resolution thumbnail.
    var imageUrl = video.thumbnails.maxResUrl;
    try {
      final imageRes = await http.head(Uri.parse(imageUrl));
      if (imageRes.statusCode != 200) imageUrl = video.thumbnails.highResUrl;
    } on Exception {
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
      streamInfo: streamInfo,
      remoteImageUrl: imageUrl,
      lyrics: "", // TODO: by default, get from closed captions
      songStoredAt: null,
      size: null,
      caching: caching,
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

  /// The videos YouTube lists next to [videoId], most related first.
  ///
  /// Throws [NetworkException] if the network is not accessible.
  static Future<List<Video>> getRelatedVideos(
    String videoId,
    YoutubeExplode? yt,
  ) async {
    NetworkUtils.check();

    return withYT(yt, (client) async {
      final video = await client.videos.get(videoId);
      final related = await client.videos.getRelatedVideos(video);
      final videos = related?.toList() ?? <Video>[];
      // A video is not related to itself, and the same one is not listed twice.
      final seen = <String>{videoId};
      return [
        for (final video in videos)
          if (seen.add(video.id.value)) video,
      ];
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

  /// Runs [f] with [yt], or, when [yt] is null, with a client of its own that
  /// is closed once [f] has finished. A client the caller passes is left open,
  /// since the caller wants to use it again.
  static Future<T> withYT<T>(
    YoutubeExplode? yt,
    Future<T> Function(YoutubeExplode yt) f,
  ) async {
    if (yt != null) return f(yt);
    final temp = YoutubeExplode();
    try {
      return await f(temp);
    } finally {
      temp.close();
    }
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
