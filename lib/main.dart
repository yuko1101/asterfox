import 'dart:async';
import 'dart:io';

import 'package:asterfox/data/device_settings_data.dart';
import 'package:asterfox/music/manager/audio_data_manager.dart';
import 'package:asterfox/screens/asterfox_screen.dart';
import 'package:asterfox/system/firebase/cloud_firestore.dart';
import 'package:asterfox/utils/overlay_utils.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screens/widget_screen.dart';
import 'package:easy_app/utils/os.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wear/wear.dart';

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

final MusicManager musicManager = MusicManager(true);
late final bool isWearOS;
final bool shouldInitializeFirebase =
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

late final bool isOverlay;

Future<void> main() async {
  isOverlay = false;
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      OverlayUtils.init();

      try {
        await Wear.instance.getShape();
        isWearOS = true;
      } on Exception {
        isWearOS = false;
      }
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
      if (!isOverlay) await musicManager.init();

      // run this after initializing the music manager.
      if (!isOverlay) {
        await DeviceSettingsData.applyMusicManagerSettings();
      }

      await LocalMusicsData.init();

      // run this after initializing Firebase, LocalMusicsData, and SettingsData.
      if (shouldInitializeFirebase && !isOverlay) {
        await CloudFirestoreManager.init();
      }

      await CustomColors.load();
      await SongHistoryData.init(musicManager);

      if (!isOverlay) {
        HomeScreen.processNotificationList = ProcessNotificationList();
      }
      await EasyApp.initialize(
        homeScreen: isWearOS || isOverlay
            ? const WidgetScreen(child: SizedBox())
            : HomeScreen(),
        languages: [
          "ja_JP",
          "en_US",
        ],
        activateConnectionChecker: true,
      );

      final shareFilesDir =
          Directory("${(await getTemporaryDirectory()).path}/share_files");
      if (shareFilesDir.existsSync()) shareFilesDir.delete(recursive: true);

      debugPrint("localPath: ${EasyApp.localPath}");
      if (OS.isMobile() && !isOverlay) {
        SharingIntent.init();
      }

      runApp(const AsterfoxApp());

      // void notify() async {
      //   final notifier = ValueNotifier(0);
      //   await HomeScreen.processNotificationList.push(
      //     ProcessNotificationData(
      //       title: Text(const Uuid().v4()),
      //       description: const Text("Test Process"),
      //       future: () async {
      //         await Future.delayed(const Duration(seconds: 1));
      //         notifier.value = notifier.value + 1;
      //         await Future.delayed(const Duration(seconds: 1));
      //         notifier.value = notifier.value + 1;
      //         await Future.delayed(const Duration(seconds: 1));
      //         notifier.value = notifier.value + 1;
      //         await Future.delayed(const Duration(seconds: 1));
      //         notifier.value = notifier.value + 1;
      //       }(),
      //       progressListenable: notifier,
      //       maxProgress: 4,
      //     ),
      //   );
      //   notify();
      // }

      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
      // notify();
      // await Future.delayed(const Duration(milliseconds: 200));
    },
    (error, stack) {
      if (kDebugMode) throw error;
      if (shouldInitializeFirebase) {
        FirebaseCrashlytics.instance.recordError(error, stack);
      }
    },
  );
}

@pragma("vm:entry-point")
void overlayMain() async {
  if (isWearOS) return;
  isOverlay = true;
  WidgetsFlutterBinding.ensureInitialized();
  OverlayUtils.init();

  OverlayUtils.listenData(
    type: ListenDataType.playingState,
    callback: (res) {
      musicManager.playingStateNotifier.value = PlayingState.values
          .firstWhere((playingState) => playingState.name == res.data);
    },
  );

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTextStyle(
          style: TextStyle(), child: AsterfoxMainWatchScreen(WearShape.square)),
    ),
  );
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
