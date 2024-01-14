import 'package:flutter/material.dart';

import '../../main.dart';
import '../../music/manager/notifiers/audio_state_notifier.dart';

class CurrentSongTitle extends StatelessWidget {
  const CurrentSongTitle({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.currentSongNotifier,
      builder: (_, audioState, __) {
        final musicData = audioState.currentSong;
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Text(
              musicData?.title ?? "",
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CurrentSongAuthor extends StatelessWidget {
  const CurrentSongAuthor({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.currentSongNotifier,
      builder: (_, audioState, __) {
        final musicData = audioState.currentSong;
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Text(
              musicData?.author ?? "",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }
}
