import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/manager/audio_data_manager.dart';
import 'package:asterfox/music/manager/music_listener.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';

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
          tooltip: Language.getText("shuffle"),
        );
      },
    );
  }
}

class PreviousSongButton extends StatelessWidget {
  const PreviousSongButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MusicData?>(
      valueListenable: musicManager.currentSongNotifier,
      builder: (_, song, __) => IconButton(
        icon: const Icon(Icons.skip_previous),
        onPressed: song == null ? null : () async => await musicManager.playback(true),
        tooltip: Language.getText("play_previous_song"),
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
            return IconButton(
              icon: const Icon(Icons.play_arrow),
              iconSize: 32.0,
              onPressed: null,
              tooltip: Language.getText("play"),
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
              tooltip: Language.getText("play"),
            );
          case PlayingState.playing:
            return IconButton(
              icon: const Icon(Icons.pause),
              iconSize: 32.0,
              onPressed: musicManager.pause,
              tooltip: Language.getText("pause"),
            );
          case PlayingState.unknown:
            return IconButton(
              icon: const Icon(Icons.play_arrow),
              iconSize: 32.0,
              onPressed: null,
              tooltip: Language.getText("play"),
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
          tooltip: Language.getText("play_next_song"),
        );
      },
    );
  }
}
