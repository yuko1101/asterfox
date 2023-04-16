import 'dart:async';
import 'dart:io';

import 'package:asterfox/data/device_settings_data.dart';
import 'package:asterfox/screens/asterfox_screen.dart';
import 'package:asterfox/system/firebase/cloud_firestore.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/os.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'data/custom_colors.dart';
import 'data/local_musics_data.dart';
import 'data/settings_data.dart';
import 'data/song_history_data.dart';
import 'firebase_options.dart';
import 'music/manager/music_manager.dart';
import 'screens/home_screen.dart';
import 'system/sharing_intent.dart';
import 'system/theme/theme.dart';
import 'widget/process_notifications/process_notification_list.dart';

late final MusicManager musicManager;
final bool shouldInitializeFirebase =
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await EasyApp.initializePath();

      await SettingsData.init();

      await DeviceSettingsData.init();

      // Firebase set-up
      if (shouldInitializeFirebase) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        if (!kDebugMode) {
          FlutterError.onError =
              FirebaseCrashlytics.instance.recordFlutterFatalError;
        }
      }

      // run this before initializing HomeScreen
      musicManager = MusicManager(true);
      await musicManager.init();

      // run this after initializing the music manager.
      await DeviceSettingsData.applyMusicManagerSettings();

      await LocalMusicsData.init();

      // run this after initializing Firebase, LocalMusicsData, and SettingsData.
      if (shouldInitializeFirebase) await CloudFirestoreManager.init();

      await CustomColors.load();
      await SongHistoryData.init(musicManager);

      HomeScreen.processNotificationList = ProcessNotificationList();
      await EasyApp.initialize(
        homeScreen: HomeScreen(),
        languages: [
          "ja_JP",
          "en_US",
        ],
        activateConnectionChecker: true,
      );

      final shareFilesDir =
          Directory("${(await getTemporaryDirectory()).path}/share_files");
      if (shareFilesDir.existsSync()) shareFilesDir.delete(recursive: true);

      init();
      runApp(const AsterfoxApp());
    },
    (error, stack) {
      if (kDebugMode) throw error;
      if (shouldInitializeFirebase) {
        FirebaseCrashlytics.instance.recordError(error, stack);
      }
    },
  );
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
