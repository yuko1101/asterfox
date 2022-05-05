
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../main.dart';

class RepeatButton extends StatelessWidget {
  const RepeatButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RepeatState>(
      valueListenable: musicManager.repeatModeNotifier,
      builder: (context, value, child) {
        switch (value) {
          case RepeatState.none:
            return IconButton(
              icon: Icon(Icons.repeat, color: Theme.of(context).disabledColor),
              onPressed: musicManager.nextRepeatMode,
              tooltip: "リピート: OFF",
            );
          case RepeatState.all:
            return IconButton(
              icon: const Icon(Icons.repeat),
              onPressed: musicManager.nextRepeatMode,
              tooltip: "リピート: キュー",
            );
          case RepeatState.one:
            return IconButton(
              icon: const Icon(Icons.repeat_one),
              onPressed: musicManager.nextRepeatMode,
              tooltip: "リピート: 1曲",
            );
        }
      },
    );
  }
}

repeatStateFromString(String value) {
  switch (value) {
    case "off":
      return RepeatState.none;
    case "all":
      return RepeatState.all;
    case "one":
      return RepeatState.one;
  }
}

repeatStateToString(RepeatState value) {
  switch (value) {
    case RepeatState.none:
      return "off";
    case RepeatState.all:
      return "all";
    case RepeatState.one:
      return "one";
  }
}

repeatStateToLoopMode(RepeatState value) {
  switch (value) {
    case RepeatState.none:
      return LoopMode.off;
    case RepeatState.all:
      return LoopMode.all;
    case RepeatState.one:
      return LoopMode.one;
  }
}

loopModeToRepeatState(LoopMode value) {
  switch (value) {
    case LoopMode.off:
      return RepeatState.none;
    case LoopMode.all:
      return RepeatState.all;
    case LoopMode.one:
      return RepeatState.one;
  }
}

enum RepeatState {
  none,
  all,
  one,
}

