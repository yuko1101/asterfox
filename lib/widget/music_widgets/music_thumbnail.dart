import 'dart:io';

import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:flutter/material.dart';

class MusicThumbnail extends StatelessWidget {
  const MusicThumbnail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioBase?>(
        valueListenable: musicManager.currentSongNotifier,
        builder: (context, song, child) {
          final image = song == null ? Image.asset("assets/images/asterfox.png") 
              : song.isLocal ? Image.file(File(song.imageUrl))
              : Image.network(song.imageUrl);
          return SizedBox(
            height: 50,
            width: 80,
            child: FittedBox(
              fit: BoxFit.contain,
              child: image,
            ),
          );
        },
    );
  }
}
