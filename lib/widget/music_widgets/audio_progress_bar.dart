import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';

import '../../data/custom_colors.dart';
import '../../main.dart';
import '../../music/manager/audio_data_manager.dart';
import '../../utils/responsive.dart';

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.progressNotifier,
      builder: (_, state, __) {
        final Color color = CustomColors.getColor("accent");
        final progress = state.progress;
        return ProgressBar(
          progressBarColor: color,
          thumbColor: color,
          bufferedBarColor: color.withOpacity(0.2),
          baseBarColor: color.withOpacity(0.15),
          thumbRadius: Responsive.isMobile(context) ? 10 : 5,
          progress: progress.position,
          buffered: progress.buffer,
          total: progress.duration,
          onSeek: musicManager.seek,
          timeLabelLocation: TimeLabelLocation.none,
        );
      },
    );
  }
}
