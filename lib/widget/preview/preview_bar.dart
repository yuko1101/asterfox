import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';

import '../../data/custom_colors.dart';
import '../../main.dart';
import '../../music/manager/audio_data_manager.dart';
import '../../music/manager/song_preview.dart';
import '../../system/theme/theme.dart';

/// The bar a preview is heard and steered with.
///
/// It stands at the bottom of the screen the preview was started from and says
/// what is being heard, so that a preview is not something the app does behind
/// the user's back. It only exists while a preview is on: stopping one takes it
/// away.
class PreviewBar extends StatelessWidget {
  const PreviewBar({required this.preview, super.key});

  final SongPreview preview;

  @override
  Widget build(BuildContext context) {
    final extraColors = Theme.of(context).extraColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: 1,
          color: extraColors.primary.withValues(alpha: 0.06),
        ),
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
            top: 6,
            bottom: 6 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.headphones, size: 18, color: extraColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<PreviewingVideo?>(
                      valueListenable: preview.previewing,
                      builder: (context, previewing, __) => Text(
                        previewing == null
                            ? ""
                            : "${previewing.song.title} - "
                                "${previewing.song.author}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          color: extraColors.primary,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.value.stop_preview,
                    onPressed: preview.stop,
                  ),
                ],
              ),
              Row(
                children: [
                  ValueListenableBuilder(
                    valueListenable: preview.playing,
                    builder: (context, playing, __) => IconButton(
                      iconSize: 32,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      tooltip: playing ? l10n.value.pause : l10n.value.play,
                      onPressed: preview.togglePlay,
                    ),
                  ),
                  Expanded(
                    child: ValueListenableBuilder<ProgressBarState>(
                      valueListenable: preview.progress,
                      builder: (context, progress, __) => ProgressBar(
                        progressBarColor: CustomColors.getColor("accent"),
                        thumbColor: CustomColors.getColor("accent"),
                        bufferedBarColor: CustomColors.getColor("accent")
                            .withValues(alpha: 0.2),
                        baseBarColor: CustomColors.getColor("accent")
                            .withValues(alpha: 0.15),
                        thumbRadius: 5,
                        progress: progress.position,
                        buffered: progress.buffer,
                        total: progress.duration,
                        onSeek: preview.seek,
                        timeLabelTextStyle:
                            TextStyle(fontSize: 12, color: extraColors.secondary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
