import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';

import '../../main.dart';
import '../../music/manager/notifiers/audio_state_notifier.dart';

class RepeatButton extends StatelessWidget {
  const RepeatButton({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.repeatModeNotifier,
      builder: (context, audioState, child) {
        final l10n = AppLocalizations.of(context)!;
        switch (audioState.repeatState) {
          case RepeatState.none:
            return IconButton(
              icon: Icon(Icons.repeat, color: Theme.of(context).disabledColor),
              onPressed: musicManager.nextRepeatMode,
              tooltip: "${l10n.repeat}: ${l10n.off}",
            );
          case RepeatState.all:
            return IconButton(
              icon: const Icon(Icons.repeat),
              onPressed: musicManager.nextRepeatMode,
              tooltip: "${l10n.repeat}: ${l10n.queue}",
            );
          case RepeatState.one:
            return IconButton(
              icon: const Icon(Icons.repeat_one),
              onPressed: musicManager.nextRepeatMode,
              tooltip: "${l10n.repeat}: 1${l10n.song}",
            );
        }
      },
    );
  }
}

RepeatState repeatStateFromString(String value) {
  switch (value) {
    case "none":
      return RepeatState.none;
    case "all":
      return RepeatState.all;
    case "one":
      return RepeatState.one;
    default:
      return RepeatState.none;
  }
}

String repeatStateToString(RepeatState value) {
  switch (value) {
    case RepeatState.none:
      return "none";
    case RepeatState.all:
      return "all";
    case RepeatState.one:
      return "one";
  }
}

LoopMode repeatStateToLoopMode(RepeatState value) {
  switch (value) {
    case RepeatState.none:
      return LoopMode.off;
    case RepeatState.all:
      return LoopMode.all;
    case RepeatState.one:
      return LoopMode.one;
  }
}

RepeatState loopModeToRepeatState(LoopMode value) {
  switch (value) {
    case LoopMode.off:
      return RepeatState.none;
    case LoopMode.all:
      return RepeatState.all;
    case LoopMode.one:
      return RepeatState.one;
  }
}

AudioServiceRepeatMode repeatStateToAudioServiceRepeatMode(RepeatState value) {
  switch (value) {
    case RepeatState.none:
      return AudioServiceRepeatMode.none;
    case RepeatState.all:
      return AudioServiceRepeatMode.all;
    case RepeatState.one:
      return AudioServiceRepeatMode.one;
  }
}

enum RepeatState {
  none,
  all,
  one,
}
