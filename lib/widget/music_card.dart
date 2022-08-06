import 'package:flutter/material.dart';

import '../data/local_musics_data.dart';
import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/manager/audio_data_manager.dart';
import '../system/theme/theme.dart';
import 'music_widgets/music_thumbnail.dart';

class MusicCardWidget extends StatelessWidget {
  const MusicCardWidget({
    required this.song,
    this.isPlaying = false,
    this.isLinked = false,
    required this.index,
    this.onTap,
    this.onRemove,
    Key? key,
  }) : super(key: key);

  final MusicData song;
  final bool isPlaying;
  final bool isLinked;
  final int index;

  final dynamic Function(int)? onTap;
  final dynamic Function(int, DismissDirection)? onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(song.key),
      background: Container(
        color: Theme.of(context).extraColors.primary.withOpacity(0.07),
      ),
      child: InkWell(
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
                  playing: isPlaying,
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
          if (onTap != null) {
            onTap!(index);
            return;
          }
          if (isLinked) {
            musicManager.seek(
              Duration.zero,
              index: musicManager.audioDataManager.playlist
                  .indexWhere((element) => element.key == song.key),
            );
          }
        },
      ),
      onDismissed: (DismissDirection dismissDirection) async {
        if (onRemove != null) {
          onRemove!(index, dismissDirection);
          return;
        }
        if (isLinked) await musicManager.remove(song.key);
        song.destroy();
      },
    );
  }
}

class MusicCardLeading extends StatelessWidget {
  const MusicCardLeading({
    required this.song,
    required this.playing,
    Key? key,
  }) : super(key: key);

  final MusicData song;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Opacity(
            opacity: playing ? 0.3 : 1.0,
            child: SizedBox(
              height: 60,
              width: 60,
              child: FittedBox(
                child: MusicImageWidget(song.imageUrl),
                fit: BoxFit.fitHeight,
                clipBehavior: Clip.antiAlias,
              ),
            ),
          ),
        ),
        if (playing)
          Center(
            child: SizedBox(
              height: 25,
              width: 25,
              child: ValueListenableBuilder<PlayingState>(
                valueListenable: musicManager.playingStateNotifier,
                builder: (_, playingState, __) {
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
