import 'dart:io';

import 'package:asterfox/data/temporary_data.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';
import 'package:easy_app/utils/network_utils.dart';

import '../main.dart';
import '../system/firebase/cloud_firestore.dart';
import '../system/theme/theme.dart';
import '../widget/music_widgets/repeat_button.dart';

// TODO: move `repeat_mode` and `volume` into TemporaryData
class SettingsData {
  static late ConfigFile settings;
  static const Map<String, dynamic> defaultData = {
    "theme": "light",
    "repeat_mode": "none",
    "auto_download": false,
    "volume": 1.0,
  };
  static Future<void> init() async {
    settings = await ConfigFile(
      File("${EasyApp.localPath}/settings.json"),
      defaultData,
    ).load();
  }

  static Future<void> save() async {
    await settings.save();
    if (NetworkUtils.networkConnected()) {
      await CloudFirestoreManager.upload();
    } else {
      TemporaryData.data.set(key: "offline_changes", value: true);
      await TemporaryData.save();
    }
  }

  static Future<void> applySettings() async {
    if (AppTheme.themeNotifier.value != getValue(key: "theme") as String) {
      AppTheme.themeNotifier.value = getValue(key: "theme") as String;
    }
  }

  static bool _initializedRepeatListener = false;
  static Future<void> applyMusicManagerSettings() async {
    if (!_initializedRepeatListener) {
      musicManager.repeatModeNotifier.addListener(() {
        print("repeatModeNotifier.addListener");
        settings.set(
          key: "repeat_mode",
          value: repeatStateToString(musicManager.audioDataManager.repeatState),
        );
        save();
      });
      _initializedRepeatListener = true;
    }
    if (repeatStateToString(musicManager.repeatModeNotifier.value) !=
        getValue(key: "repeat_mode") as String) {
      musicManager.setRepeatMode(
          repeatStateFromString(getValue(key: "repeat_mode") as String));
    }
    musicManager.baseVolumeNotifier.value = getValue(key: "volume");
    await musicManager.updateVolume();
  }

  static dynamic getValue({String? key, List<String>? keys}) {
    if (key == null && keys == null) return settings.data;
    if (key != null) return settings.getValue(key) ?? defaultData[key];
    if (keys != null) {
      var data = settings.data;
      for (var key in keys) {
        data = data[key] ?? defaultData[key];
      }
      return data;
    }
  }
}
