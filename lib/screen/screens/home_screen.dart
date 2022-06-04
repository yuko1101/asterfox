import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/manager/audio_data_manager.dart';
import 'package:asterfox/screen/base_screen.dart';
import 'package:asterfox/utils/in_app_notification/in_app_notification.dart';
import 'package:asterfox/widget/music_footer.dart';
import 'package:asterfox/widget/playlist_widget.dart';
import 'package:asterfox/widget/song_search.dart';
import 'package:flutter/material.dart';


final homeNotification = InAppNotification();

class HomeScreen extends BaseScreen {
  HomeScreen() : super(
    screen: Stack(
      children: [
        ValueListenableBuilder<PlayingState>(
          valueListenable: musicManager.playingStateNotifier,
          builder: (_, __, ___) => ValueListenableBuilder<List<MusicData>>(
            valueListenable: musicManager.shuffledPlaylistNotifier,
            builder: (_, songs, __) => ValueListenableBuilder<MusicData?>(
              valueListenable: musicManager.currentSongNotifier,
              builder: (_, currentSong, __) => PlaylistWidget(
                padding: const EdgeInsets.only(top: 15),
                songs: songs,
                playing: currentSong,
                linked: true,
              ),
            ),
          ),
        ),
        homeNotification
      ]
    ),
    appBar: const HomeScreenAppBar(),
    footer: const MusicFooter(),
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
        IconButton(onPressed: () => openSearch(context), icon: const Icon(Icons.search)),
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
        icon: const Icon(Icons.menu),
        tooltip: "メニュー",
      ),
    );
  }
  openSearch(BuildContext context) {
    showSearch(context: context, delegate: SongSearch());
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

