import 'package:asterfox/config/custom_colors.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/manager/audio_data_manager.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/system/theme/theme_options.dart';
import 'package:asterfox/util/color_util.dart';
import 'package:flutter/material.dart';

class MusicCardWidget extends StatelessWidget {
  const MusicCardWidget({
    required this.song,
    required this.cardIndex,
    this.playing = false,
    this.linked = false,
    Key? key
  }) : super(key: key);

  final MusicData song;
  final bool playing;
  final bool linked;
  final int cardIndex;

  @override
  Widget build(BuildContext context) {
    onTap() {
      if (linked) {
        musicManager.seek(
          Duration.zero,
          index: musicManager.audioDataManager.playlist.indexWhere((element) => element.key == song.key)
      );
      }
    }
    final child = Theme.of(context).themeOptions.isShadowed.level > ShadowLevel.medium.level ?
      Container(
        margin: const EdgeInsets.only(top: 2.0),
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(2, 2),
              )
            ]
        ),
        child: Material(
          child: ListTile(
            title: Text(song.title),
            onTap: onTap,
            tileColor: playing ? CustomColors.getColor("accent").withOpacity(0.3) : Theme.of(context).extraColors.themeColor,
          ),
        ),
      )
        :
      Container(
        margin: const EdgeInsets.only(top: 2.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).extraColors.primary.withOpacity(0.05), width: 2),
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
              onTap: onTap,
              trailing: playing ? SizedBox(width: 20, height: 20, child: ValueListenableBuilder<PlayingState>(
                valueListenable: musicManager.playingStateNotifier,
                builder: (context, value, child) {
                  return value == PlayingState.playing ? const Image(image: AssetImage("assets/images/playing.gif"), fit: BoxFit.cover)
                    : const Icon(Icons.pause);
                }
              )) : null,
              tileColor: Theme.of(context).extraColors.quaternary,

            ),
          ),
        ),
      );
    return Dismissible(
        key: Key(song.key),
        child: child,
        onDismissed: (DismissDirection dismissDirection) {
          if (linked) musicManager.remove(song.key);
        },
    );
  }
}
