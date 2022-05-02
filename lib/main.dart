import 'dart:async';

import 'package:asterfox/config/custom_colors.dart';
import 'package:asterfox/config/local_musics_data.dart';
import 'package:asterfox/config/settings_data.dart';
import 'package:asterfox/screen/page_manager.dart';
import 'package:asterfox/screen/screens/main_screen.dart';
import 'package:asterfox/system/languages.dart';
import 'package:asterfox/system/sharing_intent.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/util/network_util.dart';
import 'package:asterfox/util/os.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'music/manager/music_manager.dart';

late final MusicManager musicManager;
late final String localPath;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NetworkUtils.init();

  if (OS.getOS() == OSType.windows) DartVLC.initialize();

  musicManager = MusicManager();
  await musicManager.init();
  if (OS.getOS() != OSType.web) localPath = (await getApplicationDocumentsDirectory()).path;
  await SettingsData.init();
  SettingsData.applySettings();
  await LocalMusicsData.init();
  await CustomColors.load();
  await Language.init();

  init();
  runApp(const AsterfoxApp());
}

void init() async {
  debugPrint("localPath: $localPath");
  if (OS.getOS() != OSType.windows) SharingIntent.init();
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
          home: WillPopScope(
            onWillPop: () async => PageManager.goBack(context),
            child: const MainScreen()
          ),
          debugShowCheckedModeBanner: false,
        );
      },
      valueListenable: AppTheme.themeNotifier,
    );
  }
}