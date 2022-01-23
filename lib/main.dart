import 'dart:async';

import 'package:asterfox/music/youtube_music.dart';
import 'package:asterfox/screen/screens/home_screen.dart';
import 'package:asterfox/theme/theme.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

import 'music/manager/audio_handler.dart';
import 'music/manager/music_manager.dart';

late final MusicManager musicManager;
late final String localPath;

Future<void> main() async {
  musicManager = MusicManager();
  await musicManager.init();
  localPath = (await getApplicationDocumentsDirectory()).path;
  init();
  runApp(const AsterfoxApp());
  // print(await getAudioURL("fWUKNrngFz8"));
}

void init() async {
  debugPrint("localPath: $localPath");
}

ValueNotifier<String> themeNotifier = ValueNotifier<String>("light");

class AsterfoxApp extends StatelessWidget {
  const AsterfoxApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        builder: (context, value, child) {

          return MaterialApp(
            title: 'Asterfox',
            theme: themes[value],
            home: HomeScreen(),
          );
        },
        valueListenable: themeNotifier,
    );
  }
}
