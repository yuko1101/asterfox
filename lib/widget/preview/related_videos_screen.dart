import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide MusicData;

import '../../main.dart';
import '../../music/manager/song_preview.dart';
import '../../music/music_data/music_data.dart';
import '../../music/utils/music_data_utils.dart';
import '../../music/utils/youtube_music_utils.dart';
import '../../system/exceptions/network_exception.dart';
import '../../system/home_screen_music_manager.dart';
import '../../system/theme/theme.dart';
import '../screen/stateful_scaffold_screen.dart';
import '../toast/toast_manager.dart';
import 'preview_bar.dart';
import 'video_list_tile.dart';

/// The videos YouTube lists next to a song, with a way to hear each of them.
///
/// The list is what YouTube says is related to a song of the queue, which is
/// where music that is not in the library is found. Hearing one of them is a
/// preview: it is played on a player of its own and enters nothing, so that
/// looking for music does not change the queue.
class RelatedVideosScreen extends StatefulScaffoldScreen {
  const RelatedVideosScreen({
    required this.song,
    this.fetchRelated,
    this.fetchMusicData,
    this.addToQueue,
    this.createPreview,
    super.key,
  });

  /// The song the videos are related to.
  final MusicData song;

  /// Fetches the videos related to a song, by its audio id.
  ///
  /// The whole of the YouTube side of this screen is behind the four functions
  /// below, so that a test can drive the screen without a network.
  final Future<List<Video>> Function(String audioId)? fetchRelated;

  /// The data of the video at a url, which is what a preview hears.
  final Future<MusicData<CachingDisabled>> Function(String mediaUrl)?
      fetchMusicData;

  /// Adds the video at a url to the queue of the app.
  final Future<void> Function(String mediaUrl)? addToQueue;

  /// Makes the preview this screen hears songs through.
  ///
  /// Replaced in tests, where nothing is heard on a libmpv player.
  final SongPreview Function()? createPreview;

  @override
  State<RelatedVideosScreen> createState() => _RelatedVideosScreenState();
}

class _RelatedVideosScreenState
    extends StatefulScaffoldScreenState<RelatedVideosScreen> {
  late final SongPreview preview = (widget.createPreview ?? SongPreview.new)();

  final ValueNotifier<List<Video>> videos = ValueNotifier([]);
  final ValueNotifier<bool> loading = ValueNotifier(true);

  /// What went wrong while the videos were fetched, or null.
  final ValueNotifier<Object?> error = ValueNotifier(null);

  /// The video whose preview is being prepared, or null.
  ///
  /// A video that is not on this device has its audio asked YouTube for before
  /// it can be heard, so the row that was tapped says what it is doing until
  /// the audio arrives.
  final ValueNotifier<String?> preparingVideoId = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    loadRelatedVideos();
  }

  @override
  void dispose() {
    // Whatever was being heard, none of it is heard once this screen is gone.
    preview.dispose();
    videos.dispose();
    loading.dispose();
    error.dispose();
    preparingVideoId.dispose();
    super.dispose();
  }

  /// Asks YouTube what is related to the song of this screen.
  Future<void> loadRelatedVideos() async {
    loading.value = true;
    error.value = null;
    try {
      final fetched = await (widget.fetchRelated ?? _fetchRelated)(
        widget.song.audioId,
      );
      if (!mounted) return;
      videos.value = fetched;
    } on Exception catch (e) {
      if (!mounted) return;
      error.value = e;
    } finally {
      // The screen can be left while the request is on its way, and a disposed
      // notifier is not to be written to.
      if (mounted) loading.value = false;
    }
  }

  static Future<List<Video>> _fetchRelated(String audioId) =>
      YouTubeMusicUtils.getRelatedVideos(audioId, null);

  @override
  PreferredSizeWidget appBar(BuildContext context) {
    return AppBar(
      title: Text(l10n.value.related_videos),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.value.go_back,
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.value.refresh_all,
          onPressed: loadRelatedVideos,
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RelatedSong(song: widget.song),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: loading,
            builder: (context, isLoading, __) => isLoading
                ? const Center(child: CircularProgressIndicator())
                : _Videos(
                    videos: videos,
                    error: error,
                    preview: preview,
                    loadingVideoId: preparingVideoId,
                    onPreview: previewVideo,
                    onAddToQueue: addToQueue,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget? footer(BuildContext context) {
    // The bar is how a preview is heard, so it only stands while there is one.
    return ValueListenableBuilder<PreviewingVideo?>(
      valueListenable: preview.previewing,
      builder: (context, previewing, __) => Visibility(
        visible: previewing != null,
        child: PreviewBar(preview: preview),
      ),
    );
  }

  /// Plays [video] on the preview player, standing aside for the queue.
  Future<void> previewVideo(Video video) async {
    final videoId = video.id.value;
    preparingVideoId.value = videoId;
    try {
      // The same data the queue would hold, so that a preview hears what the
      // song would sound like if it were added.
      final song = await (widget.fetchMusicData ?? MusicDataUtils.fetchFromUrl)(
        video.url,
      );
      // The row that is heard is known by the video it came from, rather than
      // by the id of the audio, since a song not from YouTube has no video id
      // to be recognised by.
      await preview.start(song, videoId: videoId);
    } on Exception catch (e) {
      if (!mounted) return;
      ToastManager.showSimpleToast(
        msg: Text(e is NetworkException
            ? l10n.value.network_not_accessible
            : l10n.value.song_unplayable),
        icon: const Icon(Icons.error_outline, color: Colors.red),
      );
    } finally {
      if (mounted && preparingVideoId.value == videoId) {
        preparingVideoId.value = null;
      }
    }
  }

  /// Adds [video] to the queue of the app.
  Future<void> addToQueue(Video video) async {
    if (widget.addToQueue != null) return widget.addToQueue!(video.url);
    await HomeScreenMusicManager.addSong(
      caching: CachingEnabled.random(),
      mediaUrl: video.url,
    );
  }
}

/// The song the videos are related to, so that the list is known for what it is
/// a list of.
class _RelatedSong extends StatelessWidget {
  const _RelatedSong({required this.song});

  final MusicData song;

  @override
  Widget build(BuildContext context) {
    final extraColors = Theme.of(context).extraColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: extraColors.primary.withValues(alpha: 0.04),
      child: Row(
        children: [
          Icon(Icons.music_note, size: 18, color: extraColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${song.title} - ${song.author}",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: extraColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The videos, or why there are none.
class _Videos extends StatelessWidget {
  const _Videos({
    required this.videos,
    required this.error,
    required this.preview,
    required this.loadingVideoId,
    required this.onPreview,
    required this.onAddToQueue,
  });

  final ValueNotifier<List<Video>> videos;
  final ValueNotifier<Object?> error;
  final SongPreview preview;
  final ValueNotifier<String?> loadingVideoId;
  final Future<void> Function(Video) onPreview;
  final Future<void> Function(Video) onAddToQueue;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Object?>(
      valueListenable: error,
      builder: (context, error, __) {
        if (error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                error is NetworkException
                    ? l10n.value.network_not_accessible
                    : l10n.value.song_unable_to_load,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).extraColors.secondary,
                ),
              ),
            ),
          );
        }
        return ValueListenableBuilder<List<Video>>(
          valueListenable: videos,
          builder: (context, videos, __) => videos.isEmpty
              ? Center(
                  child: Text(
                    l10n.value.no_related_videos,
                    style: TextStyle(
                      color: Theme.of(context).extraColors.secondary,
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: videos.length,
                  // What the preview is doing with a row is read per row, so
                  // that starting or stopping a preview rebuilds the rows that
                  // care about it rather than the whole list.
                  itemBuilder: (context, index) => VideoListTileForPreview(
                    video: videos[index],
                    preview: preview,
                    loadingVideoId: loadingVideoId,
                    onPreview: onPreview,
                    onAddToQueue: onAddToQueue,
                  ),
                ),
        );
      },
    );
  }
}
