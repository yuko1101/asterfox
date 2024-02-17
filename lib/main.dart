import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import 'screens/debug_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings/audio_channel_settings_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/theme_settings_screen.dart';
import 'screens/song_history_screen.dart';
import 'system/firebase/cloud_firestore.dart';
import 'system/theme/theme.dart';
import 'utils/network_utils.dart';
import 'widget/process_notifications/process_notification_list.dart';

final MusicManager musicManager = MusicManager(true);
late final bool isWearOS;
final bool shouldInitializeFirebase =
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

late final String localPath;

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

      if (Platform.isAndroid) {
        final modes = await FlutterDisplayMode.supported;
        modes.forEach(print);
        await FlutterDisplayMode.setHighRefreshRate();
      }

      if (!kIsWeb) localPath = (await getApplicationDocumentsDirectory()).path;

      final wearOSCheckFile = File("$localPath/wear_os");
      final wearOSCheckFileExists = wearOSCheckFile.existsSync();
      if (isWearOS && !wearOSCheckFileExists) {
        wearOSCheckFile.createSync();
      } else if (!isWearOS && wearOSCheckFileExists) {
        wearOSCheckFile.deleteSync();
      }

      await SettingsData.init();
      await SettingsData.applySettings();

      await DeviceSettingsData.init();

      NetworkUtils.init(ConnectivityResult.mobile);

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

      final shareFilesDir =
          Directory("${(await getTemporaryDirectory()).path}/share_files");
      if (shareFilesDir.existsSync()) shareFilesDir.delete(recursive: true);

      debugPrint("localPath: $localPath");

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            "/home": (context) => HomeScreen(),
            "/history": (context) => const SongHistoryScreen(),
            "/settings": (context) => const SettingsScreen(),
            "/settings/theme": (context) => const ThemeSettingsScreen(),
            "/settings/audioChannel": (context) =>
                const AudioChannelSettingsScreen(),
            "/debug": (context) => const DebugScreen(),
          },
        );
      },
    );
  }
}

void exitApp([bool force = false]) {
  if (Platform.isAndroid && !force) {
    SystemNavigator.pop();
  } else {
    exit(0);
  }
}
