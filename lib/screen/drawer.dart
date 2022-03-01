import 'package:asterfox/screen/screens/debug_screen.dart';
import 'package:asterfox/theme/theme.dart';
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
                          onPressed: () {}
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
                          onPressed: () {}
                        ),
                        DrawerListTile(
                          title: "Debug",
                          icon: Icons.bug_report,
                          onPressed: () {
                            // close drawer
                            Navigator.pop(context);

                            //open the debug page
                            Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const DebugScreen())
                            );
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
