import 'package:asterfox/util/responsive.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: musicManager.progressNotifier,
      builder: (_, value, __) {
        // print( "current: "+ value.current.inMilliseconds.toString());
        return ProgressBar(
          // progressBarColor: settings.primaryColor,
          // thumbColor: settings.primaryColor,
          // bufferedBarColor: settings.primaryColor.withOpacity(0.35),
          // baseBarColor: settings.primaryColor.withOpacity(0.175),
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