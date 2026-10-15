import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide MusicData;

import '../../main.dart';
import '../../music/manager/audio_data_manager.dart';
import '../../music/manager/song_preview.dart';
import '../../system/theme/theme.dart';
import '../music_widgets/music_thumbnail.dart';
import '../notifiers_widget.dart';

/// One video of a list of videos, as a row that can be heard.
///
/// The row itself plays the video on a preview player; the button at its right
/// adds it to the queue instead, so that hearing a video and keeping it are two
/// decisions rather than one.
class VideoListTile extends StatelessWidget {
  const VideoListTile({
    required this.video,
    required this.onPreview,
    required this.onAddToQueue,
    this.isInQueue = false,
    this.isPreviewing = false,
    this.isLoadingPreview = false,
    this.onStopPreview,
    super.key,
  });

  final Video video;

  /// Called when the row is tapped, which plays the video on the preview
  /// player.
  final VoidCallback onPreview;

  /// Called when the button at the right is pressed, which adds the video to
  /// the queue.
  final VoidCallback onAddToQueue;

  /// Whether the video is already in the queue.
  final bool isInQueue;

  /// Whether this video is the one the preview is on.
  final bool isPreviewing;

  /// Whether the audio of this video is being fetched for a preview.
  final bool isLoadingPreview;

  /// Called when the stop button of a previewing row is pressed.
  final VoidCallback? onStopPreview;

  @override
  Widget build(BuildContext context) {
    final extraColors = Theme.of(context).extraColors;

    return InkWell(
      onTap: isPreviewing ? null : onPreview,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 4, top: 6, bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 45,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _VideoThumbnail(videoId: video.id.value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    video.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(fontSize: 15, color: extraColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // Only the author is shown. The library reports a related
                    // video with no length and with a view count that is the
                    // digits of "207M" rather than 207 million, so neither is
                    // worth showing next to the title.
                    video.author,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 12, color: extraColors.secondary),
                  ),
                ],
              ),
            ),
            if (isLoadingPreview)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (isPreviewing)
              IconButton(
                icon: const Icon(Icons.stop),
                tooltip: l10n.value.stop_preview,
                onPressed: onStopPreview,
              )
            else
              IconButton(
                icon: Icon(
                  isInQueue ? Icons.playlist_play : Icons.playlist_add,
                ),
                tooltip: isInQueue
                    ? l10n.value.in_queue
                    : l10n.value.add_to_queue,
                onPressed: isInQueue ? null : onAddToQueue,
              ),
          ],
        ),
      ),
    );
  }

}

/// A row of a related video, told what the preview and the queue are doing with
/// it.
///
/// The state of the preview is read here rather than by the list of videos, so
/// that starting or stopping a preview rebuilds the rows that care about it and
/// not the whole list.
class VideoListTileForPreview extends StatelessWidget {
  const VideoListTileForPreview({
    required this.video,
    required this.preview,
    required this.loadingVideoId,
    required this.onPreview,
    required this.onAddToQueue,
    super.key,
  });

  final Video video;
  final SongPreview preview;
  final ValueListenable<String?> loadingVideoId;
  final Future<void> Function(Video) onPreview;
  final Future<void> Function(Video) onAddToQueue;

  @override
  Widget build(BuildContext context) {
    return DoubleNotifierWidget<PreviewingVideo?, String?>(
      notifier1: preview.previewing,
      notifier2: loadingVideoId,
      builder: (context, previewing, loadingAudioId, _) {
        return ValueListenableBuilder<AudioState>(
          valueListenable: musicManager.audioStateManager.songsNotifier,
          builder: (context, state, __) => VideoListTile(
            video: video,
            isPreviewing: previewing?.videoId == video.id.value,
            isLoadingPreview: loadingAudioId == video.id.value,
            isInQueue: state.playlist.any((s) => s.audioId == video.id.value),
            onPreview: () => onPreview(video),
            onAddToQueue: () => onAddToQueue(video),
            onStopPreview: () => preview.stop(),
          ),
        );
      },
    );
  }
}

/// The picture of a video, with the app's own image where there is none.
///
/// A video that is not stored has no picture on the device, so this is the one
/// place a picture is fetched over the network rather than read from a file.
class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      ThumbnailSet(videoId).mediumResUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          getDefaultImage(BoxFit.cover),
    );
  }
}
