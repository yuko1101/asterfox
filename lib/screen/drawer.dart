import 'package:asterfox/screen/page_manager.dart';
import 'package:asterfox/screen/screens/debug_screen.dart';
import 'package:asterfox/screen/screens/home_screen.dart';
import 'package:asterfox/screen/screens/main_screen.dart';
import 'package:asterfox/screen/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 210,
        child: Row(
          children: [
            Expanded(
              child: Drawer(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: SingleChildScrollView(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        DrawerHeader(
                          child: Center(
                            child: ListTile(
                              leading: Image.asset(
                                "assets/images/asterfox.png",
                                scale: 0.1,
                              ),
                              title: const Text(
                                "Asterfox",
                                textScaleFactor: 1.3
                              ),
                            ),
                          ),
                        ),
                        DrawerListTile(
                          title: "Home",
                          icon: Icons.home,
                          onPressed: () {
                            if (screenNotifier.value is HomeScreen) return;
                            pushPage(context, HomeScreen(), close: true);
                          }
                        ),
                        DrawerListTile(
                          title: "Playlist",
                          icon: Icons.playlist_play,
                          onPressed: () {}
                        ),
                        DrawerListTile(
                          title: "Playback",
                          icon: Icons.replay,
                          onPressed: () {}
                        ),
                        DrawerListTile(
                          title: "Settings",
                          icon: Icons.settings,
                          onPressed: () {
                            if (screenNotifier.value is SettingsScreen) return;
                            pushPage(context, SettingsScreen(), close: true);
                          }
                        ),
                        DrawerListTile(
                          title: "Debug",
                          icon: Icons.bug_report,
                          onPressed: () {
                            if (screenNotifier.value is DebugScreen) return;
                            pushPage(context, const DebugScreen(), close: true);
                          }
                        )
                      ]
                    )
                  )
                )
              )
            )
          ]
        )
    );
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile(
      {required this.title, required this.icon, required this.onPressed, Key? key})
      : super(key: key);

  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: InkWell(
        child: ListTile(
          onTap: onPressed,
          horizontalTitleGap: 0.0,
          leading: Icon(icon, color: Theme.of(context).textTheme.headline3!.color),
          title: Text(
            title,
            style: TextStyle(color: Theme.of(context).textTheme.headline3!.color),
          ),
        ),
      ),
    );
  }
}
