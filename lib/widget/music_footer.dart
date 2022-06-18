import 'package:easy_app/utils/responsive.dart';
import 'package:flutter/material.dart';

import 'music_widgets/audio_progress_bar.dart';
import 'music_widgets/download_button.dart';
import 'music_widgets/more_actions_button.dart';
import 'music_widgets/music_buttons.dart';
import 'music_widgets/music_thumbnail.dart';
import 'music_widgets/repeat_button.dart';
import 'music_widgets/song_text.dart';
import 'music_widgets/time_text.dart';

class MusicFooter extends StatelessWidget with PreferredSizeWidget {
  const MusicFooter({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isMobile(context)) {
      return SizedBox(
        height: 75,
        child: Column(
          children: [
            const Expanded(
              child: AudioProgressBar(),
            ),
            Row(
              children: [
                const PreviousSongButton(),
                const PlayButton(),
                const NextSongButton(),
                const SizedBox(width: 30),
                const TimeText(),
                const Spacer(),
                const MusicThumbnail(),
                const SizedBox(width: 30),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    CurrentSongTitle(),
                    CurrentSongAuthor(),
                  ],
                ),
                const Spacer(),
                const RepeatButton(),
                const ShuffleButton(),
                const DownloadButton(),
                const MoreActionsButton(),
              ],
            ),
          ],
        ),
      );
    }
    return const MobileMusicFooter();
  }
}

class MobileMusicFooter extends StatelessWidget {
  const MobileMusicFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.5),
              spreadRadius:   5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            )
          ],
          color: Theme.of(context).backgroundColor
      ),
      height: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
                height: 70,
                width: 70,
                child: const FittedBox(
                  child: MusicThumbnail(),
                  fit: BoxFit.fitHeight,
                  clipBehavior: Clip.antiAlias
                )
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    CurrentSongTitle(),
                    CurrentSongAuthor()
                  ],
                ),
              ),
              const SizedBox(width: 10)
            ]
          ),
          Container(
            margin: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              children: const [
                Align(
                  child: TimeText(),
                  alignment: Alignment.bottomRight,
                ),
                AudioProgressBar()
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    ShuffleButton(),
                    RepeatButton(),
                    PreviousSongButton(),
                  ],
                ),
              ),
              const PlayButton(),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    NextSongButton(),
                    DownloadButton(),
                    MoreActionsButton(),
                  ],
                ),
              ),
            ]
          )
        ]
      )
    );
  }
}
