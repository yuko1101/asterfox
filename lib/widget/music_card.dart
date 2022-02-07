import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:flutter/material.dart';

class MusicCardWidget extends StatelessWidget {
  const MusicCardWidget({
    required this.song,
    Key? key
  }) : super(key: key);

  final AudioBase song;

  @override
  Widget build(BuildContext context) {
    return Dismissible(key: Key(song.getKey()), child:
      Card(
        child: ListTile(
          title: Text(song.title),
          onTap: () {},
        ),
      ),
    );
  }
}
