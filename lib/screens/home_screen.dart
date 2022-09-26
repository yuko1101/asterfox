import 'package:easy_app/screen/base_screens/scaffold_screen.dart';
import 'package:easy_app/utils/in_app_notification/in_app_notification.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/manager/audio_data_manager.dart';
import '../widget/music_footer.dart';
import '../widget/music_widgets/lyrics_button.dart';
import '../widget/music_widgets/volume_widget.dart';
import '../widget/notifiers_widget.dart';
import '../widget/playlist_widget.dart';
import '../widget/search/song_search.dart';

class HomeScreen extends ScaffoldScreen {
  static late InAppNotification homeNotification;
  HomeScreen({
    Key? key,
  }) : super(
          body: Builder(
            builder: (context) {
              final volumeWidgetKey = GlobalKey<VolumeWidgetState>();
              final volumeWidget = VolumeWidget(key: volumeWidgetKey);

              return Stack(
                children: [
                  TripleNotifierWidget<PlayingState, List<MusicData>,
                      MusicData?>(
                    notifier1: musicManager.playingStateNotifier,
                    notifier2: musicManager.shuffledPlaylistNotifier,
                    notifier3: musicManager.currentSongNotifier,
                    builder:
                        (context, playingState, playlist, currentSong, child) =>
                            PlaylistWidget(
                      songs: playlist,
                      playing: currentSong,
                      isLinked: true,
                      padding: const EdgeInsets.only(top: 15),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      homeNotification,
                      const LyricsButton(),
                    ],
                  ),

                  // <------ Volume Button ------>
                  ValueListenableBuilder<bool>(
                    valueListenable: volumeWidget.openedNotifier,
                    builder: (context, opened, _) {
                      if (opened) {
                        return GestureDetector(
                          onTap: volumeWidgetKey.currentState?.close,
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),
                  Positioned(
                    bottom: 5,
                    left: 5,
                    child: volumeWidget,
                  ),
                  // <----------------------------->
                ],
              );
            },
          ),
          appBar: const HomeScreenAppBar(),
          footer: const MusicFooter(),
          key: key,
        );
}

class HomeScreenAppBar extends StatelessWidget with PreferredSizeWidget {
  const HomeScreenAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final animatedMenuIconKey = GlobalKey<AnimatedMenuIconState>();
    final animatedMenuIcon = AnimatedMenuIcon(key: animatedMenuIconKey);

    return AppBar(
      title: Row(
        children: [
          SizedBox(
            height: 35,
            width: 35,
            child: FittedBox(
              child: Image.asset("assets/images/asterfox.png"),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 5),
          const Text("Asterfox")
        ],
        mainAxisAlignment: MainAxisAlignment.start,
      ),
      actions: [
        IconButton(
            onPressed: () async {
              animatedMenuIconKey.currentState?.controller.forward();
              await showSearch(context: context, delegate: SongSearch());
              animatedMenuIconKey.currentState?.controller.reverse();
            },
            icon: const Icon(Icons.search)),
        // IconButton(
        //   onPressed: () async {
        //     debugPrint("pressed");
        //     homeNotification.pushNotification(NotificationData(child: const Text("a")));
        //     await HomeScreenMusicManager.addSongByID("j_dj8uHvePE");
        //
        //     debugPrint("added from home_screen");
        //     // await musicManager.play();
        //     // debugPrint("played");
        //   },
        //   icon: const Icon(Icons.add),
        // )
      ],
      leading: IconButton(
        onPressed: () => AppDrawerController(context).openDrawer(),
        icon: animatedMenuIcon,
        tooltip: Language.getText("menu"),
      ),
    );
  }
}

class AppDrawerController {
  AppDrawerController(this.context);
  final BuildContext context;

  void openDrawer() {
    final ScaffoldState scaffoldState = Scaffold.of(context);
    if (!scaffoldState.isDrawerOpen) {
      FocusScope.of(context).requestFocus(FocusNode());
      scaffoldState.openDrawer();
    }
  }

  void openEndDrawer() {
    final ScaffoldState scaffoldState = Scaffold.of(context);
    if (scaffoldState.isEndDrawerOpen) {
      FocusScope.of(context).requestFocus(FocusNode());
      scaffoldState.openEndDrawer();
    }
  }
}

class AnimatedMenuIcon extends StatefulWidget {
  const AnimatedMenuIcon({Key? key}) : super(key: key);

  @override
  State<AnimatedMenuIcon> createState() => AnimatedMenuIconState();
}

class AnimatedMenuIconState extends State<AnimatedMenuIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedIcon(icon: AnimatedIcons.menu_arrow, progress: controller);
  }
}
