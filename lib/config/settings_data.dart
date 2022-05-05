import 'package:asterfox/main.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'dart:io';

import 'package:asterfox/util/config_file.dart';

class SettingsData {
  static late ConfigFile settings;
  static Map<String, dynamic> defaultData = {
    "theme": "light",
    "useAudioSession": true,
  };
  static Future<void> init() async {
    settings = await ConfigFile(File("$localPath/settings.json"), defaultData).load();
  }

  static Future<void> save() async {
    settings.save();
  }

  static Future<void> applySettings() async {
    if (AppTheme.themeNotifier.value != settings.getValue("theme") as String) AppTheme.themeNotifier.value = settings.getValue("theme") as String;
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