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
    this.songWidgetBuilder,
    this.onMove,
    this.onRemove,
    this.onTap,
    Key? key
  }) : super(key: key);

  final List<MusicData> songs;
  final MusicData? playing;
  final bool linked;
  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext, int)? songWidgetBuilder;

  final dynamic Function(int, int)? onMove;
  final dynamic Function(int, DismissDirection)? onRemove;
  final dynamic Function(int)? onTap;


  @override
  _PlaylistWidgetState createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget> {
  @override
  Widget build(BuildContext context) {

  if ((widget.onRemove != null || widget.onTap != null) && widget.songWidgetBuilder != null) {
    throw ArgumentError("You can't use onRemove or onTap if you use songWidgetBuilder.");
  }

    return SizedBox(
      child: SingleChildScrollView(
        padding: widget.padding,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: widget.songWidgetBuilder ?? (context, index) => MusicCardWidget(
              song: widget.songs[index],
              playing: widget.songs[index].key == widget.playing?.key && widget.linked,
              key: Key(widget.songs[index].key),
              linked: widget.linked,
              index: index,
              onTap: widget.onTap,
              onRemove: widget.onRemove,
          ),
          itemCount: widget.songs.length,
          onReorder: (oldIndex, newIndex) async {
            if (oldIndex < newIndex) newIndex -= 1;

            print("oldIndex: $oldIndex, newIndex: $newIndex");

            if (widget.linked && widget.onMove == null) await musicManager.move(oldIndex, newIndex);
            setState(() {
              if (!widget.linked) {
                final song = widget.songs.removeAt(oldIndex);
                widget.songs.insert(newIndex, song);
              }

              if (widget.onMove != null) widget.onMove!(oldIndex, newIndex);

            });
          }
        ),
      ),
    );
  }
}
