import 'dart:async';
import 'dart:io';

import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screens/widget_screen.dart';
import 'package:easy_app/utils/os.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wear/wear.dart';

import 'data/custom_colors.dart';
import 'data/device_settings_data.dart';
import 'data/local_musics_data.dart';
import 'data/settings_data.dart';
import 'data/song_history_data.dart';
import 'firebase_options.dart';
import 'music/manager/music_manager.dart';
import 'screens/asterfox_screen.dart';
import 'screens/home_screen.dart';
import 'system/firebase/cloud_firestore.dart';
import 'system/sharing_intent.dart';
import 'system/theme/theme.dart';
import 'widget/process_notifications/process_notification_list.dart';

final List<String> supportedLanguages = [
  "ja_JP",
  "en_US",
];

final MusicManager musicManager = MusicManager(true);
late final bool isWearOS;
final bool shouldInitializeFirebase =
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top],
      );

      try {
        await Wear.instance.getShape();
        isWearOS = true;
      } on Exception {
        isWearOS = false;
      }

      if (OS.getOS() == OSType.android) {
        final modes = await FlutterDisplayMode.supported;
        modes.forEach(print);
        await FlutterDisplayMode.setHighRefreshRate();
      }

      await EasyApp.initializePath();
      final wearOSCheckFile = File("${EasyApp.localPath}/wear_os");
      final wearOSCheckFileExists = wearOSCheckFile.existsSync();
      if (isWearOS && !wearOSCheckFileExists) {
        wearOSCheckFile.createSync();
      } else if (!isWearOS && wearOSCheckFileExists) {
        wearOSCheckFile.deleteSync();
      }

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
      await musicManager.init();

      // run this after initializing the music manager.
      await DeviceSettingsData.applyMusicManagerSettings();

      await LocalMusicsData.init();

      // run this after initializing Firebase, LocalMusicsData, and SettingsData.
      if (shouldInitializeFirebase) {
        await CloudFirestoreManager.init();
      }

      await CustomColors.load();
      await SongHistoryData.init(musicManager);

      HomeScreen.processNotificationList = ProcessNotificationList();

      await EasyApp.initialize(
        homeScreen:
            isWearOS ? const WidgetScreen(child: SizedBox()) : HomeScreen(),
        languages: supportedLanguages,
        activateConnectionChecker: true,
      );

      final shareFilesDir =
          Directory("${(await getTemporaryDirectory()).path}/share_files");
      if (shareFilesDir.existsSync()) shareFilesDir.delete(recursive: true);

      debugPrint("localPath: ${EasyApp.localPath}");
      if (OS.isMobile()) {
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

class AsterfoxApp extends StatelessWidget {
  const AsterfoxApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeData>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, theme, child) {
        return MaterialApp(
          title: "Asterfox",
          theme: theme,
          home: const AsterfoxScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

void exitApp([bool force = false]) {
  if (OS.getOS() == OSType.android && !force) {
    SystemNavigator.pop();
  } else {
    exit(0);
  }
}
