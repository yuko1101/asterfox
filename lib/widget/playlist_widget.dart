import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/widget/music_card.dart';
import 'package:flutter/material.dart';


class PlaylistWidget extends StatefulWidget {
  const PlaylistWidget({
    required this.songs,
    this.playing,
    this.linked = false,
    this.padding,
    Key? key
  }) : super(key: key);

  final List<MusicData> songs;
  final MusicData? playing;
  final bool linked;
  final EdgeInsetsGeometry? padding;

  @override
  _PlaylistWidgetState createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget> {
  @override
  Widget build(BuildContext context) {

    return SizedBox(
      child: SingleChildScrollView(
        padding: widget.padding,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => MusicCardWidget(
              song: widget.songs[index],
              playing: widget.songs[index].key == widget.playing?.key,
              key: Key(widget.songs[index].key),
              linked: widget.linked,
              cardIndex: index,
          ),
          itemCount: widget.songs.length,
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;

            print("oldIndex: $oldIndex, newIndex: $newIndex");

            final song = widget.songs.removeAt(oldIndex);


            if (widget.linked) musicManager.move(oldIndex, newIndex);

            setState(() {
              widget.songs.insert(newIndex, song);
            });
          }
        ),
      ),
    );
  }
}
