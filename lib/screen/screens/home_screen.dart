import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/audio_source/youtube_audio.dart';
import 'package:asterfox/music/youtube_music.dart';
import 'package:asterfox/screen/base_screen.dart';
import 'package:asterfox/screen/drawer.dart';
import 'package:asterfox/util/in_app_notification/in_app_notification.dart';
import 'package:asterfox/util/in_app_notification/notification_data.dart';
import 'package:asterfox/widget/music_footer.dart';
import 'package:asterfox/widget/playlist_widget.dart';
import 'package:flutter/material.dart';

final homeNotification = InAppNotification();

class HomeScreen extends BaseScreen {
  HomeScreen({Key? key}) : super(
    screen: Stack(
      children: [
        ValueListenableBuilder<List<AudioBase>>(
          valueListenable: musicManager.playlistNotifier,
          builder: (_, songs, __) => PlaylistWidget(
            songs: songs,
            playing: musicManager.currentSongNotifier.value,
            linked: true,
          ),
        ),
        homeNotification
      ]
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
        IconButton(
          onPressed: () async {
            debugPrint("pressed");
            homeNotification.pushNotification(NotificationData(title: "aa"));
            await musicManager.add(
              // YouTubeAudio(
              //     url: "https://cdn.discordapp.com/attachments/513142781502423050/928884270041301052/PIKASONIC__Tatsunoshin_-_Lockdown_ft.NEONA_KOTONOHOUSE_Remix.mp3",
              //     title: "LockDown",
              //     description: "",
              //     author: "PIKASONIC",
              //     authorId: "",
              //     id: "",
              //   duration: 0,
              //   isLocal: false,
              // )
                (await getYouTubeAudio("j_dj8uHvePE"))!
            );
            debugPrint("added");
            // await musicManager.play();
            // debugPrint("played");
          },
          icon: const Icon(Icons.add),
        )
      ],
      leading: IconButton(onPressed: () => DrawerController(context).openDrawer(), icon: const Icon(Icons.menu)),
    );
  }
  openSearch(BuildContext context) {
    if (themeNotifier.value != "dark") {

      themeNotifier.value = "dark";
    } else {
      themeNotifier.value = "light";
    // showSearch(context: context, delegate: delegate);
    }
  }
}

class DrawerController {
  DrawerController(this.context);
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
