import 'dart:async';
import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/data/settings_data.dart';
import 'package:asterfox/data/song_history_data.dart';
import 'package:asterfox/screens/debug_screen.dart';
import 'package:asterfox/screens/home_screen.dart';
import 'package:asterfox/screens/settings/settings_screen.dart';
import 'package:asterfox/screens/song_history_screen.dart';
import 'package:asterfox/system/sharing_intent.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/drawer.dart';
import 'package:easy_app/screen/main_screen.dart';
import 'package:easy_app/utils/in_app_notification/in_app_notification.dart';
import 'package:easy_app/utils/os.dart';
import 'package:flutter/material.dart';
import 'music/manager/music_manager.dart';

late final MusicManager musicManager;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyApp.initializePath();

  await SettingsData.init();
  SettingsData.applySettings();

  musicManager = MusicManager(true);
  await musicManager.init();

  await SettingsData.applyMusicManagerSettings();

  await CustomColors.load();
  await SongHistoryData.init(musicManager);

  HomeScreen.homeNotification = InAppNotification(
    borderColor: CustomColors.getColor("accent"),
  );
  await EasyApp.initialize(
    homeScreen: HomeScreen(),
    languages: [
      "ja_JP",
      "en_US",
    ],
    activateConnectionChecker: true
  );

  await LocalMusicsData.init();

  init();
  runApp(const AsterfoxApp());
}

void init() async {
  debugPrint("localPath: ${EasyApp.localPath}");
  if (OS.isMobile()) {
    SharingIntent.init();
  }
}


class AsterfoxApp extends StatelessWidget {
  const AsterfoxApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      builder: (context, value, child) {
        return MaterialApp(
          title: 'Asterfox',
          theme: AppTheme.themes[value],
          home: MainScreen(sideMenu: SideMenu(
            appIcon: Image.asset(
              "assets/images/asterfox.png",
              scale: 0.1,
            ),
            title: const Text(
                "Asterfox",
                textScaleFactor: 1.3
            ),
            items: [
              SideMenuItem(
                  title: const Text("Home"),
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    if (EasyApp.currentScreen is HomeScreen) return;
                    EasyApp.pushPage(context, HomeScreen());
                  }
              ),
              SideMenuItem(
                  title: const Text("Playlist"),
                  icon: const Icon(Icons.playlist_play),
                  onPressed: () {}
              ),
              SideMenuItem(
                  title: const Text("History"),
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    if (EasyApp.currentScreen is SongHistoryScreen) return;
                    EasyApp.pushPage(context, SongHistoryScreen());
                  }
              ),
              SideMenuItem(
                  title: const Text("Settings"),
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    if (EasyApp.currentScreen is SettingsScreen) return;
                    EasyApp.pushPage(context, SettingsScreen());
                  }
              ),
              SideMenuItem(
                  title: const Text("Debug"),
                  icon: const Icon(Icons.bug_report),
                  onPressed: () {
                    if (EasyApp.currentScreen is DebugScreen) return;
                    EasyApp.pushPage(context, const DebugScreen());
                  }
              )
            ],
          ),),
          debugShowCheckedModeBanner: false,
        );
      },
      valueListenable: AppTheme.themeNotifier,
    );
  }
}