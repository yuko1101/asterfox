import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:flutter/material.dart';

class CurrentSongTitle extends StatelessWidget {
  const CurrentSongTitle({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MusicData?>(
      valueListenable: musicManager.currentSongNotifier,
      builder: (_, musicData, __) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Text(musicData?.title ?? "", style: const TextStyle(fontSize: 20))
          ),
        );
      },
    );
  }
}

class CurrentSongAuthor extends StatelessWidget {
  const CurrentSongAuthor({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MusicData?>(
      valueListenable: musicManager.currentSongNotifier,
      builder: (_, musicData, __) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child:
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Text(musicData?.author ?? "", style: const TextStyle(fontSize: 18, color: Colors.grey))
          ),
        );
      },
    );
  }
}