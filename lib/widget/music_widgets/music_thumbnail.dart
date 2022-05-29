import 'dart:io';

import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/util/network_util.dart';
import 'package:flutter/material.dart';

final Image defaultImage = Image.asset("assets/images/asterfox.png");

final _httpRegex = RegExp(r'^https?:\/\/.+$');


class MusicThumbnail extends StatelessWidget {
  const MusicThumbnail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MusicData?>(
        valueListenable: musicManager.currentSongNotifier,
        builder: (context, song, child) {

          return SizedBox(
            height: 50,
            width: 80,
            child: FittedBox(
              fit: BoxFit.contain,
              child: _ImageWidget(song?.imageUrls ?? []),
            ),
          );
        },
    );
  }
}

class _ImageWidget extends StatelessWidget {
  const _ImageWidget(this.images, {Key? key}) : super(key: key);
  final List<String> images;
  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return defaultImage;
    }
    if (_httpRegex.hasMatch(images[0])) {
      return Image.network(images[0], errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) => _ImageWidget(images.sublist(1)));
    }
    return Image.file(File(images[0]));
  }

}