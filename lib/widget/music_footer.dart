import 'package:asterfox/main.dart';
import 'package:asterfox/theme/theme.dart';
import 'package:asterfox/util/responsive.dart';
import 'package:flutter/material.dart';

import 'music_widgets/audio_progress_bar.dart';
import 'music_widgets/music_buttons.dart';
import 'music_widgets/music_thumbnail.dart';
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
                // RepeatButton(),
                // ShuffleButton(),
                // DownloadButton(),
                // OptionButton(),
              ],
            ),
          ],
        ),
      );
    }
    return ValueListenableBuilder<String>(
      valueListenable: themeNotifier,
      builder: (_, value, __) => Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: themes[value]!.shadowColor.withOpacity(0.5),
                spreadRadius:   5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              )
            ],
            color: themes[value]!.backgroundColor
            ),
          height: 170,
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Row(children: [
              const SizedBox(width: 10),
              const MusicThumbnail(),
              const SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [CurrentSongTitle(), CurrentSongAuthor()],
              )
            ]),
            Row(
              children: [
                const SizedBox(width: 30),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: const [TimeText()],
                        mainAxisAlignment: MainAxisAlignment.end,
                      ),
                      const AudioProgressBar()
                    ],
                  ),
                ),
                const SizedBox(width: 30)
              ],
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              // ShuffleButton(),
              // RepeatButton(),
              const PreviousSongButton(),
              const PlayButton(),
              const NextSongButton(),
              // DownloadButton(),
              // OptionButton(),
            ])
          ])),
    );
  }
}
