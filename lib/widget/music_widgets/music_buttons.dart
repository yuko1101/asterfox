import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/manager/music_listener.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../music/manager/audio_data_manager.dart';

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: musicManager.shuffleModeNotifier,
      builder: (context, isEnabled, child) {
        return IconButton(
          icon: (isEnabled)
              ? const Icon(Icons.shuffle)
              : Icon(Icons.shuffle, color: Theme.of(context).disabledColor),
          onPressed: () {
            musicManager.toggleShuffle();
          },
          tooltip: "シャッフル",
        );
      },
    );
  }
}

class PreviousSongButton extends StatelessWidget {
  const PreviousSongButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioBase?>(
      valueListenable: musicManager.currentSongNotifier,
      builder: (_, song, __) => IconButton(
        icon: const Icon(Icons.skip_previous),
        onPressed: song == null ? null : () async => await musicManager.playback(true),
        tooltip: "一つ前の曲を再生",
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayingState>(
      valueListenable: musicManager.playingStateNotifier,
      builder: (_, value, __) {
        switch (value) {
          case PlayingState.disabled:
            return const IconButton(
              icon: Icon(Icons.play_arrow),
              iconSize: 32.0,
              onPressed: null,
              tooltip: "再生",
            );
          case PlayingState.loading:
            return Container(
              margin: const EdgeInsets.all(8.0),
              width: 32.0,
              height: 32.0,
              child: const CircularProgressIndicator(),
            );
          case PlayingState.paused:
            return IconButton(
              icon: const Icon(Icons.play_arrow),
              iconSize: 32.0,
              onPressed: musicManager.play,
              tooltip: "再生",
            );
          case PlayingState.playing:
            return IconButton(
              icon: const Icon(Icons.pause),
              iconSize: 32.0,
              onPressed: musicManager.pause,
              tooltip: "一時停止",
            );
          case PlayingState.unknown:
            return const IconButton(
              icon: Icon(Icons.play_arrow),
              iconSize: 32.0,
              onPressed: null,
              tooltip: "再生",
            );
        }
      },
    );
  }
}

class NextSongButton extends StatelessWidget {
  const NextSongButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: musicManager.hasNextNotifier,
      builder: (_, hasNext, __) {
        return IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: (hasNext) ? () => musicManager.next(true) : null,
          tooltip: "次の曲を再生",
        );
      },
    );
  }
}
