import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:flutter/material.dart';

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
      child: Card(
        child: ListTile(
          title: Text(song.title),
          onTap: () {},
          trailing: playing ? const Icon(Icons.play_arrow_outlined) : null,
        ),
      ),
      onDismissed: (DismissDirection dismissDirection) {
        musicManager.remove(song.key!);
      },
    );
  }
}
