import 'dart:io';

import 'package:easy_app/utils/network_utils.dart';
import 'package:flutter/material.dart';

import '../../data/local_musics_data.dart';
import '../../main.dart';
import '../../music/manager/notifiers/audio_state_notifier.dart';
import '../../music/utils/music_url_utils.dart';

Image getDefaultImage([BoxFit? fit]) =>
    Image.asset("assets/images/asterfox-no-image.png", fit: fit);

class MusicThumbnail extends StatelessWidget {
  const MusicThumbnail({this.fit, Key? key}) : super(key: key);
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.currentSongNotifier,
      builder: (context, audioState, child) {
        print("thumbnail: " +
            (audioState.currentSong?.title.toString() ?? "null"));
        return MusicImageWidget(
          audioState.currentSong?.imageUrl,
          fit: fit,
        );
      },
    );
  }
}

class MusicImageWidget extends StatelessWidget {
  const MusicImageWidget(this.image, {this.fit, Key? key}) : super(key: key);
  final String? image;
  final BoxFit? fit;
  @override
  Widget build(BuildContext context) {
    if (image == null || image!.isEmpty) {
      return getDefaultImage(fit);
    }
    if (image!.isUrl) {
      if (!NetworkUtils.networkAccessible()) return getDefaultImage(fit);
      return Image.network(image!, fit: fit);
    }
    return Image.file(File(image!), fit: fit);
  }
}
