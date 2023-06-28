import 'package:flutter/material.dart';

import '../main.dart';
import '../music/audio_source/music_data.dart';
import 'music_card.dart';

class PlaylistWidget extends StatefulWidget {
  const PlaylistWidget({
    required this.songs,
    this.playing,
    this.isLinked = false,
    this.padding,
    this.songWidgetBuilder,
    this.onMove,
    this.onRemove,
    this.onTap,
    Key? key,
  }) : super(key: key);

  final List<MusicData> songs;
  final MusicData? playing;
  final bool isLinked;
  final EdgeInsets? padding;
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
    if ((widget.onRemove != null || widget.onTap != null) &&
        widget.songWidgetBuilder != null) {
      throw ArgumentError(
          "You can't use onRemove or onTap if you use songWidgetBuilder.");
    }

    return ReorderableListView.builder(
      padding: widget.padding,
      physics: const BouncingScrollPhysics(),
      itemBuilder: widget.songWidgetBuilder ??
          (context, index) => MusicCardWidget(
                song: widget.songs[index],
                isPlaying: widget.songs[index].key == widget.playing?.key &&
                    widget.isLinked,
                key: Key(widget.songs[index].key),
                isLinked: widget.isLinked,
                index: index,
                onTap: widget.onTap,
                onRemove: widget.onRemove,
              ),
      itemCount: widget.songs.length,
      onReorder: (oldIndex, newIndex) async {
        if (oldIndex < newIndex) newIndex -= 1;

        print("oldIndex: $oldIndex, newIndex: $newIndex");

        if (widget.isLinked && widget.onMove == null) {
          await musicManager.move(oldIndex, newIndex);
        }
        setState(() {
          if (!widget.isLinked) {
            final song = widget.songs.removeAt(oldIndex);
            widget.songs.insert(newIndex, song);
          }

          if (widget.onMove != null) widget.onMove!(oldIndex, newIndex);
        });
      },
    );
  }
}
