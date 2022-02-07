import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/widget/music_card.dart';
import 'package:flutter/material.dart';


class QueueWidget extends StatefulWidget {
  const QueueWidget({
    required this.songs,
    Key? key
  }) : super(key: key);

  final List<AudioBase> songs;

  @override
  _QueueWidgetState createState() => _QueueWidgetState();
}

class _QueueWidgetState extends State<QueueWidget> {
  @override
  Widget build(BuildContext context) {
    return ReorderableList(
        itemBuilder: (context, index) => MusicCardWidget(song: widget.songs[index]),
        itemCount: widget.songs.length,
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) newIndex -= 1;

          final song = widget.songs.removeAt(oldIndex);

          setState(() {
            widget.songs.insert(newIndex, song);
          });
        }
    );
  }
}
