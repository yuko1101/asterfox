import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../music/manager/audio_data_manager.dart';
import '../../music/manager/notifiers/audio_state_notifier.dart';

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.isShuffledNotifier,
      builder: (context, audioState, child) {
        final isEnabled = audioState.isShuffled;
        return IconButton(
          icon: isEnabled
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
  const PreviousSongButton({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.currentSongNotifier,
      builder: (_, audioState, __) => IconButton(
        icon: const Icon(Icons.skip_previous),
        onPressed: audioState.currentSong == null
            ? null
            : () async => await musicManager.playback(true),
        tooltip: Language.getText("play_previous_song"),
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.playingStateNotifier,
      builder: (_, audioState, __) {
        switch (audioState.playingState) {
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
  const NextSongButton({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.hasNextNotifier,
      builder: (_, audioState, __) {
        return IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: audioState.hasNext ? () => musicManager.next(true) : null,
          tooltip: Language.getText("play_next_song"),
        );
      },
    );
  }
}
