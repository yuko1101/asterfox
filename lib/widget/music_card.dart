import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/manager/audio_data_manager.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/system/theme/theme_options.dart';
import 'package:asterfox/utils/color_util.dart';
import 'package:asterfox/widget/music_widgets/music_thumbnail.dart';
import 'package:flutter/material.dart';

class MusicCardWidget extends StatelessWidget {
  const MusicCardWidget({
    required this.song,
    this.playing = false,
    this.linked = false,
    required this.index,
    this.onTap,
    this.onRemove,
    Key? key
  }) : super(key: key);

  final MusicData song;
  final bool playing;
  final bool linked;
  final int index;

  final dynamic Function(int)? onTap;
  final dynamic Function(int, DismissDirection)? onRemove;

  @override
  Widget build(BuildContext context) {
    onTapFunction() {
      if (onTap != null) {
        onTap!(index);
        return;
      }
      if (linked) {
        musicManager.seek(
          Duration.zero,
          index: musicManager.audioDataManager.playlist.indexWhere((element) => element.key == song.key)
      );
      }
    }
    return Dismissible(
        key: Key(song.key),
        background: Container(
          color: Theme.of(context).extraColors.primary.withOpacity(0.07)
        ),
        child: ListTile(
          title: Text(song.title),
          subtitle: Text(song.author),
          leading: SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                Opacity(
                  opacity: playing ? 0.3 : 1.0,
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: FittedBox(
                      child: MusicImageWidget(song.imageUrls),
                      fit: BoxFit.fitHeight,
                      clipBehavior: Clip.antiAlias,
                    ),
                  ),
                ),
                if (playing) Center(
                  child: SizedBox(
                    height: 25,
                    width: 25,
                    child: ValueListenableBuilder<PlayingState>(
                      valueListenable: musicManager.playingStateNotifier,
                      builder: (_, playingState, __) {
                        if (playingState == PlayingState.playing) {
                          return Image.asset("assets/images/playing.gif", color: Theme.of(context).extraColors.primary);
                        } else {
                          return Icon(Icons.pause, color: Theme.of(context).extraColors.primary);
                        }
                      }
                    ),
                  ),
                ),
              ],
            ),
          ),
          onTap: onTapFunction,
        ),
        onDismissed: (DismissDirection dismissDirection) {
          if (onRemove != null) {
            onRemove!(index, dismissDirection);
            return;
          }
          if (linked) musicManager.remove(song.key);
        },
    );
  }
}
