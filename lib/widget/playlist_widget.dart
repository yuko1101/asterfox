import 'package:flutter/material.dart';

import '../main.dart';
import '../music/music_data/music_data.dart';
import 'music_card.dart';

class PlaylistWidget extends StatefulWidget {
  const PlaylistWidget({
    required this.songs,
    this.currentSong,
    this.isLinked = false,
    this.padding,
    this.songWidgetBuilder,
    this.onMove,
    this.onRemove,
    this.onTap,
    super.key,
  });

  final List<MusicData> songs;
  final MusicData? currentSong;
  final bool isLinked;
  final EdgeInsets? padding;
  final Widget Function(BuildContext, int)? songWidgetBuilder;

  final dynamic Function(int, int)? onMove;
  final dynamic Function(int, DismissDirection)? onRemove;
  final dynamic Function(int)? onTap;

  @override
  State<PlaylistWidget> createState() => _PlaylistWidgetState();
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
      itemBuilder: widget.songWidgetBuilder ?? buildItem,
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

  MusicCardWidget buildItem(BuildContext context, int index) => MusicCardWidget(
        song: widget.songs[index],
        isCurrentSong: widget.songs[index].key == widget.currentSong?.key &&
            widget.isLinked,
        key: Key(widget.songs[index].key),
        isLinked: widget.isLinked,
        index: index,
        onTap: widget.onTap,
        onRemove: widget.isLinked || widget.onRemove == null
            ? null
            : (i, direction) {
                setState(() {
                  widget.onRemove!(i, direction);
                });
              },
      );
}

class PlaylistWidgetWithEditMode extends PlaylistWidget {
  const PlaylistWidgetWithEditMode({
    required super.songs,
    super.currentSong,
    super.isLinked = false,
    super.padding,
    super.songWidgetBuilder,
    super.onMove,
    super.onRemove,
    super.onTap,
    super.key,
    required this.editMode,
  });

  final bool editMode;

  @override
  State<PlaylistWidget> createState() => _PlaylistWidgetWithEditModeState();
}

class _PlaylistWidgetWithEditModeState extends _PlaylistWidgetState {
  @override
  Widget build(BuildContext context) {
    final editMode = (widget as PlaylistWidgetWithEditMode).editMode;
    return editMode
        ? super.build(context)
        : ListView.builder(
            padding: widget.padding,
            physics: const BouncingScrollPhysics(),
            itemBuilder: widget.songWidgetBuilder ??
                (context, index) =>
                    buildItem(context, index).withEditMode(editMode),
            itemCount: widget.songs.length,
          );
  }
}
