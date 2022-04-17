import 'package:flutter/material.dart';

import '../../main.dart';
import 'audio_progress_bar.dart';

class TimeText extends StatelessWidget {
  const TimeText({Key? key}) : super(key: key);

  String getProgress(progress, total) {
    return total.inHours < 1
        ? total.inMinutes < 10
        ? progress.toString().split(".")[0].replaceFirst("0:0", "")
        : progress.toString().split(".")[0].replaceFirst("0:", "")
        : progress.toString().split(".")[0];
  }

  String getTotal(total) {
    return total.inHours < 1
        ? total.inMinutes < 10
        ? total.toString().split(".")[0].replaceFirst("0:0", "")
        : total.toString().split(".")[0].replaceFirst("0:", "")
        : total.toString().split(".")[0];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: musicManager.progressNotifier,
      builder: (_, value, __) {
        return Text(
          "${getProgress(value.current, value.total)} / ${getTotal(value.total)}",
          style: TextStyle(color: Theme.of(context).textTheme.headline3?.color)
        );
      }
    );
  }
}