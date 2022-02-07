import 'package:asterfox/widget/music_widgets/audio_progress_bar.dart';
import 'package:flutter/material.dart';


class ProgressNotifier extends ValueNotifier<ProgressBarState> {
  ProgressNotifier() : super(_initialValue);
  static const _initialValue = ProgressBarState(
    current: Duration.zero,
    buffered: Duration.zero,
    total: Duration.zero,
  );
}