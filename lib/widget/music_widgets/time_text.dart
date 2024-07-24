import 'package:flutter/material.dart';

import '../../main.dart';
import '../../music/manager/audio_data_manager.dart';
import '../../system/theme/theme.dart';

class TimeText extends StatelessWidget {
  const TimeText({super.key});

  String getProgress(Duration progress, Duration total) {
    return total.inHours < 1
        ? total.inMinutes < 10
            ? progress.toString().split(".")[0].replaceFirst("0:0", "")
            : progress.toString().split(".")[0].replaceFirst("0:", "")
        : progress.toString().split(".")[0];
  }

  String getTotal(Duration total) {
    return total.inHours < 1
        ? total.inMinutes < 10
            ? total.toString().split(".")[0].replaceFirst("0:0", "")
            : total.toString().split(".")[0].replaceFirst("0:", "")
        : total.toString().split(".")[0];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.progressNotifier,
      builder: (_, state, __) {
        final progress = state.progress;
        return Text(
          "${getProgress(progress.position, progress.duration)} / ${getTotal(progress.duration)}",
          style: TextStyle(
            color: Theme.of(context).extraColors.secondary,
          ),
        );
      },
    );
  }
}
