import 'dart:io';

import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/utils/extensions.dart';
import 'package:easy_app/utils/network_utils.dart';
import 'package:flutter/material.dart';

final Image defaultImage = Image.asset("assets/images/asterfox-no-image.png");

final _httpRegex = RegExp(r'^https?:\/\/.+$');


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
    if (image == null) {
      return defaultImage;
    }
    if (image!.isUrl) {
      if (!NetworkUtils.networkAccessible()) return defaultImage;
      return Image.network(image!);
    }
    return Image.file(File(image!));
  }

}