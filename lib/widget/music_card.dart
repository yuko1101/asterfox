import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/util/color_util.dart';
import 'package:flutter/material.dart';

import '../config/custom_colors.dart';

class MusicCardWidget extends StatelessWidget {
  const MusicCardWidget({
    required this.song,
    this.playing = false,
    Key? key
  }) : super(key: key);

  final AudioBase song;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(song.key!),
      child: Container(
        margin: const EdgeInsets.only(top: 2.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: getGrey(35), width: 2),
        ),
        child: Material(
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.hardEdge,
          color: Theme.of(context).textTheme.headline5?.color,
          child: ListTile(
            title: Text(song.title),
            onTap: () {},
            trailing: playing ? const Icon(Icons.play_arrow_outlined) : null,
          ),
        ),
      ),
      onDismissed: (DismissDirection dismissDirection) {
        musicManager.remove(song.key!);
      },
    );
  }
}
