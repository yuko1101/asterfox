import 'dart:convert';

import 'package:asterfox/config/local_musics_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:colored_json/colored_json.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:asterfox/system/theme/theme.dart';

class DebugScreen extends BaseScreen {
  const DebugScreen() : super(
      screen: const DebugMainScreen(),
      appBar: const DebugAppBar(),
  );
}

class DebugMainScreen extends StatelessWidget {
  const DebugMainScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(onPressed: () {
                    if (AppTheme.themeNotifier.value != "dark") {

                      AppTheme.setTheme("dark");
                    } else {
                      AppTheme.setTheme("light");
                      // showSearch(context: context, delegate: delegate);
                    }
                  }, icon: Theme.of(context).brightness == Brightness.dark ? const Icon(Icons.dark_mode) : const Icon(Icons.light_mode)),
                IconButton(onPressed: musicManager.play, icon: const Icon(Icons.play_arrow)),
                IconButton(onPressed: musicManager.pause, icon: const Icon(Icons.pause)),
                IconButton(onPressed: musicManager.next, icon: const Icon(Icons.skip_next)),
                IconButton(onPressed: musicManager.previous, icon: const Icon(Icons.skip_previous)),
                IconButton(onPressed: () {
                  LocalMusicsData.removeAllFromLocal(LocalMusicsData.getAll());
                  LocalMusicsData.saveData();
                }, icon: const Icon(Icons.delete)),
              ],
            ),
            ValueListenableBuilder<MusicData?>(
                valueListenable: musicManager.currentSongNotifier,
                builder: (_, song, __) {
                  if (song == null) {
                    return Container();
                  }
                  final String json = const JsonEncoder.withIndent("  ").convert(song.toJson());
                  return ColoredJson(
                    data: json,
                    intColor: Colors.orange,
                    doubleColor: Colors.red,
                    commaColor: Colors.grey,
                    squareBracketColor: Colors.grey,
                    colonColor: Colors.grey,
                    curlyBracketColor: Colors.purpleAccent,
                  );
                }
            )
          ],
        ),
      ),
    );
  }


}

class DebugAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DebugAppBar({
    Key? key,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Debug'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          EasyApp.popPage(context);
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}