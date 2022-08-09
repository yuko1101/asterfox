import 'dart:io';

import 'package:asterfox/music/utils/muisc_url_utils.dart';
import 'package:easy_app/utils/network_utils.dart';
import 'package:flutter/material.dart';

import '../../data/local_musics_data.dart';
import '../../main.dart';
import '../../music/audio_source/music_data.dart';

final Image defaultImage = Image.asset("assets/images/asterfox-no-image.png");

class MusicThumbnail extends StatelessWidget {
  const MusicThumbnail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MusicData?>(
      valueListenable: musicManager.currentSongNotifier,
      builder: (context, song, child) {
        return MusicImageWidget(song?.imageUrl);
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
