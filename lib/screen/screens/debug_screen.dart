import 'package:asterfox/config/local_musics_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/screen/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:asterfox/system/theme/theme.dart';

class DebugScreen extends BaseScreen {
  const DebugScreen() : super(
      screen: const DebugMainScreen(),
  );
}

class DebugMainScreen extends StatelessWidget {
  const DebugMainScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
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
            LocalMusicsData.musicData.save();
          }, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }


}
