import 'package:asterfox/config/custom_colors.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/util/responsive.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: musicManager.progressNotifier,
      builder: (_, value, __) {
        // print( "current: "+ value.current.inMilliseconds.toString());
        final Color color = CustomColors.getColor("accent");
        return ProgressBar(
          progressBarColor: color,
          thumbColor: color,
          bufferedBarColor: color.withOpacity(0.35),
          baseBarColor: color.withOpacity(0.175),
          thumbRadius: Responsive.isMobile(context) ? 10 : 5,
          progress: value.current,
          buffered: value.buffered,
          total: value.total,
          onSeek: musicManager.seek,
          timeLabelLocation: TimeLabelLocation.none,
        );
      },
    );
  }
}

class ProgressNotifier extends ValueNotifier<ProgressBarState> {
  ProgressNotifier() : super(_initialValue);
  static const _initialValue = ProgressBarState(
    current: Duration.zero,
    buffered: Duration.zero,
    total: Duration.zero,
  );
}

class ProgressBarState {
  const ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });
  final Duration current;
  final Duration buffered;
  final Duration total;
}