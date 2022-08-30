import 'dart:async';

import 'package:asterfox/data/device_settings_data.dart';
import 'package:asterfox/screens/asterfox_screen.dart';
import 'package:asterfox/system/firebase/cloud_firestore.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/in_app_notification/in_app_notification.dart';
import 'package:easy_app/utils/os.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/custom_colors.dart';
import 'data/local_musics_data.dart';
import 'data/settings_data.dart';
import 'data/song_history_data.dart';
import 'firebase_options.dart';
import 'music/manager/music_manager.dart';
import 'screens/home_screen.dart';
import 'system/sharing_intent.dart';
import 'system/theme/theme.dart';

late final MusicManager musicManager;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyApp.initializePath();

  await SettingsData.init();

  await DeviceSettingsData.init();

  // Firebase set-up
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  // run this before initializing HomeScreen
  musicManager = MusicManager(true);
  await musicManager.init();

  // run this after initializing the music manager.
  await DeviceSettingsData.applyMusicManagerSettings();

  await LocalMusicsData.init();

  // run this after initializing Firebase, LocalMusicsData, and SettingsData.
  await CloudFirestoreManager.init();

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
    activateConnectionChecker: true,
  );

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
    return ValueListenableBuilder<ThemeData>(
      builder: (context, theme, child) {
        return MaterialApp(
          title: 'Asterfox',
          theme: theme,
          home: const AsterfoxScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
      valueListenable: AppTheme.themeNotifier,
    );
  }
}
