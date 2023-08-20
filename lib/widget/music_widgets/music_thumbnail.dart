import 'dart:io';

import 'package:easy_app/utils/network_utils.dart';
import 'package:flutter/material.dart';

import '../../data/local_musics_data.dart';
import '../../main.dart';
import '../../music/manager/notifiers/audio_state_notifier.dart';
import '../../music/utils/music_url_utils.dart';

final Image defaultImage = Image.asset("assets/images/asterfox-no-image.png");

class MusicThumbnail extends StatelessWidget {
  const MusicThumbnail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.currentSongNotifier,
      builder: (context, audioState, child) {
        print("thumbnail: " +
            (audioState.currentSong?.title.toString() ?? "null"));
        return MusicImageWidget(audioState.currentSong?.imageUrl);
      },
    );
  }
}

class MusicImageWidget extends StatelessWidget {
  const MusicImageWidget(this.image, {Key? key}) : super(key: key);
  final String? image;
  @override
  Widget build(BuildContext context) {
    if (image == null || image!.isEmpty) {
      return defaultImage;
    }
    if (image!.isUrl) {
      if (!NetworkUtils.networkAccessible()) return defaultImage;
      return Image.network(image!);
    }
    return Image.file(File(image!));
  }
}
