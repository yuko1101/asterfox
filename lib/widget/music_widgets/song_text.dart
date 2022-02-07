import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class CurrentSongTitle extends StatelessWidget {
  const CurrentSongTitle({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioBase?>(
      valueListenable: musicManager.currentSongNotifier,
      builder: (_, musicData, __) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(musicData?.title ?? "", style: const TextStyle(fontSize: 20)),
        );
      },
    );
  }
}

class CurrentSongAuthor extends StatelessWidget {
  const CurrentSongAuthor({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioBase?>(
      valueListenable: musicManager.currentSongNotifier,
      builder: (_, musicData, __) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child:
          Text(musicData?.author ?? "", style: const TextStyle(fontSize: 18, color: Colors.grey)),
        );
      },
    );
  }
}