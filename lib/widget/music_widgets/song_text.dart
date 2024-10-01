import 'package:flutter/material.dart';

import '../../main.dart';
import '../../music/manager/audio_data_manager.dart';

class CurrentSongTitle extends StatelessWidget {
  const CurrentSongTitle({
    this.style,
    super.key,
  });

  final TextStyle? style;

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
              style: style,
            ),
          ),
        );
      },
    );
  }
}

class CurrentSongAuthor extends StatelessWidget {
  const CurrentSongAuthor({
    this.style,
    super.key,
  });

  final TextStyle? style;

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
              style: style,
            ),
          ),
        );
      },
    );
  }
}
