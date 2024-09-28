import 'dart:async';

import 'package:flutter/material.dart';

import '../data/local_musics_data.dart';
import '../main.dart';
import '../music/music_data/music_data.dart';
import '../music/manager/audio_data_manager.dart';
import '../system/theme/theme.dart';
import 'music_widgets/music_thumbnail.dart';

class MusicCardWidget extends StatelessWidget {
  const MusicCardWidget({
    required this.song,
    this.isCurrentSong = false,
    required this.index,
    this.onTap,
    this.onRemovePre,
    this.onRemove,
    super.key,
  });

  final MusicData song;
  final bool isCurrentSong;
  final int index;

  final dynamic Function(int, MusicData)? onTap;
  final FutureOr Function(int, MusicData, DismissDirection)? onRemovePre;
  final dynamic Function(int, MusicData, DismissDirection)? onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ObjectKey(song),
      background: Container(
        color: Theme.of(context).extraColors.primary.withOpacity(0.07),
      ),
      dismissThresholds: const {
        DismissDirection.endToStart: 0.6,
        DismissDirection.startToEnd: 0.6
      },
      child: buildCard(context),
      onDismissed: (DismissDirection dismissDirection) async {
        await onRemovePre?.call(index, song, dismissDirection);
        onRemove?.call(index, song, dismissDirection);
      },
    );
  }

  Widget buildCard(BuildContext context) {
    return InkWell(
      child: SizedBox(
        height: 80,
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 10, right: 10),
              width: 60,
              height: 60,
              child: MusicCardLeading(
                song: song,
                isCurrentSong: isCurrentSong,
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).extraColors.primary,
                    ),
                  ),
                  Text(
                    song.author,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).extraColors.secondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      onTap: () {
        onTap?.call(index, song);
      },
    );
  }

  MusicCardWidgetWithEditMode withEditMode(bool editMode) {
    return MusicCardWidgetWithEditMode(
      song: song,
      isCurrentSong: isCurrentSong,
      index: index,
      onTap: onTap,
      onRemovePre: onRemovePre,
      onRemove: onRemove,
      key: key,
      editMode: editMode,
    );
  }
}

class MusicCardLeading extends StatelessWidget {
  const MusicCardLeading({
    required this.song,
    required this.isCurrentSong,
    super.key,
  });

  final MusicData song;
  final bool isCurrentSong;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Opacity(
            opacity: isCurrentSong ? 0.3 : 1.0,
            child: SizedBox(
              height: 60,
              width: 60,
              child: FittedBox(
                fit: BoxFit.fitHeight,
                clipBehavior: Clip.antiAlias,
                child: MusicImageWidget(song.imageUrl),
              ),
            ),
          ),
        ),
        if (isCurrentSong)
          Center(
            child: SizedBox(
              height: 25,
              width: 25,
              child: ValueListenableBuilder<AudioState>(
                valueListenable:
                    musicManager.audioStateManager.playingStateNotifier,
                builder: (_, audioState, __) {
                  final PlayingState playingState = audioState.playingState;
                  if (playingState == PlayingState.playing) {
                    return Image.asset(
                      "assets/images/playing.gif",
                      color: Theme.of(context).extraColors.primary,
                    );
                  } else {
                    return Icon(
                      Icons.pause,
                      color: Theme.of(context).extraColors.primary,
                    );
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

class MusicCardWidgetWithEditMode extends MusicCardWidget {
  MusicCardWidgetWithEditMode({
    required super.song,
    super.isCurrentSong,
    required super.index,
    super.onTap,
    super.onRemovePre,
    super.onRemove,
    super.key,
    required this.editMode,
  });

  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return editMode ? super.build(context) : buildCard(context);
  }
}
