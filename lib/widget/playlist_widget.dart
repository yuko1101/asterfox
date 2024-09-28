import 'dart:async';

import 'package:flutter/material.dart';

import '../music/music_data/music_data.dart';
import 'music_card.dart';

class PlaylistWidget extends StatefulWidget {
  const PlaylistWidget({
    required this.songs,
    this.currentSong,
    this.padding,
    this.songWidgetBuilder,
    this.onMovePre,
    this.onMove,
    this.onRemovePre,
    this.onRemove,
    this.onTap,
    super.key,
  });

  final List<MusicData> songs;
  final MusicData? currentSong;
  final EdgeInsets? padding;
  final Widget Function(BuildContext, int)? songWidgetBuilder;

  /// called before setState
  final FutureOr Function(int, int, MusicData)? onMovePre;

  /// called in setState
  final dynamic Function(int, int, MusicData)? onMove;

  /// called before setState
  final FutureOr Function(int, MusicData, DismissDirection)? onRemovePre;

  /// called in setState
  final dynamic Function(int, MusicData, DismissDirection)? onRemove;
  final FutureOr Function(int, MusicData)? onTap;

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

        if (oldIndex == newIndex) return;

        widget.onMovePre?.call(oldIndex, newIndex, widget.songs[oldIndex]);

        setState(() {
          final song = widget.songs.removeAt(oldIndex);
          widget.songs.insert(newIndex, song);

          if (widget.onMove != null) widget.onMove!(oldIndex, newIndex, song);
        });
      },
    );
  }

  MusicCardWidget buildItem(BuildContext context, int index) {
    final song = widget.songs[index];
    return MusicCardWidget(
      key: ObjectKey(song),
      song: song,
      isCurrentSong: song == widget.currentSong,
      index: index,
      onTap: widget.onTap,
      onRemovePre: widget.onRemovePre,
      onRemove: widget.onRemove == null
          ? null
          : (i, song, direction) {
              setState(() {
                widget.onRemove!(i, song, direction);
              });
            },
    );
  }
}

class PlaylistWidgetWithEditMode extends PlaylistWidget {
  const PlaylistWidgetWithEditMode({
    required super.songs,
    super.currentSong,
    super.padding,
    super.songWidgetBuilder,
    super.onMovePre,
    super.onMove,
    super.onRemovePre,
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
