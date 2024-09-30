import 'package:flutter/material.dart';

import '../system/theme/theme.dart';
import '../utils/responsive.dart';
import 'music_widgets/audio_progress_bar.dart';
import 'music_widgets/download_button.dart';
import 'music_widgets/more_actions_button.dart';
import 'music_widgets/music_buttons.dart';
import 'music_widgets/music_thumbnail.dart';
import 'music_widgets/repeat_button.dart';
import 'music_widgets/song_text.dart';
import 'music_widgets/time_text.dart';

class MusicFooter extends StatelessWidget implements PreferredSizeWidget {
  const MusicFooter({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isMobile(context)) {
      return const SizedBox(
        height: 90,
        child: Column(
          children: [
            Expanded(
              child: AudioProgressBar(),
            ),
            Row(
              children: [
                PreviousSongButton(),
                PlayButton(),
                NextSongButton(),
                SizedBox(width: 30),
                TimeText(),
                SizedBox(width: 30),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 50,
                        child: MusicThumbnail(fit: BoxFit.fitHeight),
                      ),
                      SizedBox(width: 30),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CurrentSongTitle(),
                            CurrentSongAuthor(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 30),
                // TODO: add volume widget
                RepeatButton(),
                ShuffleButton(),
                DownloadButton(),
                MoreActionsButton(),
              ],
            ),
            SizedBox(height: 7),
          ],
        ),
      );
    }
    return const MobileMusicFooter();
  }
}

class MobileMusicFooter extends StatelessWidget {
  const MobileMusicFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          height: 1,
          color: Theme.of(context).extraColors.primary.withOpacity(0.04),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          // TODO: better way to draw the footer considering the bottom padding of the navigation bar
          height: 170 + MediaQuery.of(context).padding.bottom,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
                    height: 70,
                    width: 70,
                    child: const MusicThumbnail(fit: BoxFit.fitHeight),
                  ),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CurrentSongTitle(),
                        CurrentSongAuthor(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(left: 20, right: 20),
                child: const Column(
                  children: [
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TimeText(),
                    ),
                    AudioProgressBar(),
                  ],
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ShuffleButton(),
                        RepeatButton(),
                        PreviousSongButton(),
                      ],
                    ),
                  ),
                  PlayButton(),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        NextSongButton(),
                        DownloadButton(),
                        MoreActionsButton(),
                      ],
                    ),
                  ),
                ],
              ),
              // TODO: better way to draw the footer considering the bottom padding of the navigation bar
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ],
    );
  }
}
