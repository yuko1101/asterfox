import 'dart:io';

import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/audio_source/youtube_audio.dart';
import 'package:asterfox/util/network_util.dart';
import 'package:flutter/material.dart';

final Image defaultImage = Image.asset("assets/images/asterfox.png");

class MusicThumbnail extends StatelessWidget {
  const MusicThumbnail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioBase?>(
        valueListenable: musicManager.currentSongNotifier,
        builder: (context, song, child) {
          final image = song == null ? defaultImage
              : song.isLocal ? Image.file(File(song.imageUrl))
              : Image.network(
              song.imageUrl,
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                if (song is YouTubeAudio && NetworkUtils.networkAccessible()) {
                  return Image.network(
                    "https://img.youtube.com/vi/${song.id}/hqdefault.jpg",
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) => defaultImage
                  );
                }
                return defaultImage;

              }
          );
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
