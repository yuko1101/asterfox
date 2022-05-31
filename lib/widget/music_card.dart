import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/util/color_util.dart';
import 'package:flutter/material.dart';

class MusicCardWidget extends StatelessWidget {
  const MusicCardWidget({
    required this.song,
    this.playing = false,
    this.linked = false,
    Key? key
  }) : super(key: key);

  final MusicData song;
  final bool playing;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: Key(song.key),
        child: Container(
          margin: const EdgeInsets.only(top: 2.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: getGrey(35), width: 2),
          ),
          child: Material(
            borderRadius: BorderRadius.circular(10),
            // ListTileのRippleが丸まらないのを直す
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () {},
              child: ListTile(
                title: Text(song.title),
                onTap: () {},
                trailing: playing ? const Icon(Icons.play_arrow_outlined) : null,
                tileColor: Theme.of(context).textTheme.headline5?.color,

              ),
            ),
          ),
        ),
        onDismissed: (DismissDirection dismissDirection) {
          if (linked) musicManager.remove(song.key);
        },
    );
  }
}
