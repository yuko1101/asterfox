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
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wear/wear.dart';

import 'data/custom_colors.dart';
import 'data/device_settings_data.dart';
import 'data/local_musics_data.dart';
import 'data/playlist_data.dart';
import 'data/settings_data.dart';
import 'data/song_history_data.dart';
import 'firebase_options.dart';
import 'music/manager/music_manager.dart';
import 'music/playlist/playlist.dart';
import 'screens/asterfox_screen.dart';
import 'screens/debug_screen.dart';
import 'screens/home_screen.dart';
import 'screens/playlist_info_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/settings/audio_channel_settings_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/theme_settings_screen.dart';
import 'screens/song_history_screen.dart';
import 'system/firebase/cloud_firestore.dart';
import 'system/sharing_intent.dart';
import 'system/theme/theme.dart';
import 'utils/late_value_notifier.dart';
import 'utils/network_utils.dart';
import 'widget/process_notifications/process_notification_list.dart';

final MusicManager musicManager = MusicManager(true);
late final bool isWearOS;
final bool shouldInitializeFirebase =
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

late final String localPath;
late final String tempPath;

final LateValueNotifier<AppLocalizations> l10n = LateValueNotifier();

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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

      if (!kIsWeb) {
        var documentsDir = (await getApplicationDocumentsDirectory()).path;
        var tempDir = (await getTemporaryDirectory()).path;

        final appDir = "${Platform.pathSeparator}Asterfox";
        if (Platform.isWindows) {
          documentsDir += appDir;
          tempDir += appDir;
        }
        // TODO: add more os which has shared document and/or shared temp directory

        localPath = documentsDir;
        tempPath = tempDir;
      }

      final wearOSCheckFile = File("$localPath/wear_os");
      final wearOSCheckFileExists = wearOSCheckFile.existsSync();
      if (isWearOS && !wearOSCheckFileExists) {
        wearOSCheckFile.createSync();
      } else if (!isWearOS && wearOSCheckFileExists) {
        wearOSCheckFile.deleteSync();
      }

      MediaKit.ensureInitialized();

      // final player = Player();
      // await player.open(
      //   Playlist([Media("https://drive.google.com/uc?export=download&id=1IX4JIZSEN6ZiIHDo8U5JNkojfwzKBXp0")]),
      // );

      await SettingsData.init();
      await SettingsData.applySettings();

      await DeviceSettingsData.init();

      NetworkUtils.init(ConnectivityResult.mobile);

      await LocalMusicsData.init();
      await PlaylistsData.init();

      // run this before initializing HomeScreen
      await musicManager.init();

      // run this after initializing the music manager.
      await DeviceSettingsData.applyMusicManagerSettings();

      // run this after initializing Firebase, LocalMusicsData, and SettingsData.
      if (shouldInitializeFirebase) {
        await CloudFirestoreManager.init();
      }

      await CustomColors.load();
      await SongHistoryData.init(musicManager);

      HomeScreen.processNotificationList = ProcessNotificationList();

      final shareFilesDir = Directory("$tempPath/share_files");
      if (shareFilesDir.existsSync()) shareFilesDir.delete(recursive: true);

      SharingIntent.init();

      debugPrint("localPath: $localPath");

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
            "/home": (context) => const HomeScreen(),
            "/playlists": (context) => PlaylistsScreen(),
            "/history": (context) => const SongHistoryScreen(),
            "/settings": (context) => const SettingsScreen(),
            "/settings/theme": (context) => const ThemeSettingsScreen(),
            "/settings/audioChannel": (context) =>
                const AudioChannelSettingsScreen(),
            "/debug": (context) => const DebugScreen(),
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case "/playlistInfo":
                final playlist = settings.arguments as AppPlaylist;
                return MaterialPageRoute(
                  builder: (context) => PlaylistInfoScreen(playlist),
                );
              default:
                return null;
            }
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
