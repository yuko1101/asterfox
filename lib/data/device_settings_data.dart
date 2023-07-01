import 'dart:io';

import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';

import '../main.dart';
import '../widget/music_widgets/repeat_button.dart';

class DeviceSettingsData {
  static late ConfigFile data;

  static const Map<String, dynamic> defaultData = {
    "repeatMode": "none",
    "volume": 1.0,
  };

  static Future<void> init() async {
    data = await ConfigFile(
      File("${EasyApp.localPath}/device_settings.json"),
      defaultData,
    ).load();
  }

  static Future<void> save() async {
    await data.save();
  }

  static Future<void> apply() async {}

  static dynamic getValue({String? key, List<String>? keys}) {
    if (key == null && keys == null) return data.data;
    if (key != null) return data.getValue(key) ?? defaultData[key];
    if (keys != null) {
      var map = data.data;
      for (var key in keys) {
        map = map[key] ?? defaultData[key];
      }
      return map;
    }
  }

  static bool _initializedRepeatListener = false;
  static Future<void> applyMusicManagerSettings() async {
    if (!_initializedRepeatListener) {
      musicManager.repeatModeNotifier.addListener(() {
        print("repeatModeNotifier.addListener");
        data.set(
          key: "repeatMode",
          value: repeatStateToString(musicManager.audioDataManager.repeatState),
        );
        save();
      });
      _initializedRepeatListener = true;
    }
    if (repeatStateToString(musicManager.repeatModeNotifier.value) !=
        getValue(key: "repeatMode") as String) {
      musicManager.setRepeatMode(
          repeatStateFromString(getValue(key: "repeatMode") as String));
    }
    musicManager.baseVolumeNotifier.value = getValue(key: "volume");
    await musicManager.updateVolume();
  }
}
