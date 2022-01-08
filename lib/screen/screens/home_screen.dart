import 'package:asterfox/main.dart';
import 'package:asterfox/music/music_data.dart';
import 'package:asterfox/music/music_detail.dart';
import 'package:asterfox/screen/base_screen.dart';
import 'package:asterfox/screen/drawer.dart';
import 'package:flutter/material.dart';

class HomeScreen extends BaseScreen {
  HomeScreen({Key? key}) : super(
    screen: Center(
      child: TextButton(
        onPressed: () async {
          debugPrint("pressed");
          await musicManager.add(
              MusicData(
                  url: "https://cdn.discordapp.com/attachments/513142781502423050/928884270041301052/PIKASONIC__Tatsunoshin_-_Lockdown_ft.NEONA_KOTONOHOUSE_Remix.mp3",
                audioType: AudioType.remote,
                detail: MusicDetail(
                  title: "LockDown",
                  description: "",
                  author: "PIKASONIC",
                  authorId: "",
                  playedCount: 0,
                  videoId: "",
                  timestamp: DateTime.now().millisecondsSinceEpoch
                )
              )
          );
          debugPrint("added");
          await musicManager.play();
          debugPrint("played");
        },
        child: const Text("a"),
      )
    ),
    appBar: const HomeScreenAppBar(),
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
      title: const Text("Asterfox"),
      actions: [
        IconButton(onPressed: () => openSearch(context), icon: const Icon(Icons.search))
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
