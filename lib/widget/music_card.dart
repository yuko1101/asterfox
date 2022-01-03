import 'package:asterfox/music/music_data.dart';
import 'package:flutter/material.dart';

class MusicCardWidget extends StatelessWidget {
  const MusicCardWidget({
    required this.song,
    Key? key
  }) : super(key: key);

  final MusicData song;

  @override
  Widget build(BuildContext context) {
    return Dismissible(key: Key(song.uuid), child:
      Card(
        child: ListTile(
          title: Text(song.detail.title),
          onTap: () {},
        ),
      ),
    );
  }
}
