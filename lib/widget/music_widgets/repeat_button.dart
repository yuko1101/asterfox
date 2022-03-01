
import 'package:flutter/material.dart';

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

class RepeatModeNotifier extends ValueNotifier<RepeatState> {
  RepeatModeNotifier() : super(_initialValue);
  static const _initialValue = RepeatState.none;

  void nextState() {
    final next = (value.index + 1) % RepeatState.values.length;
    value = RepeatState.values[next];
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

enum RepeatState {
  none,
  all,
  one,
}

