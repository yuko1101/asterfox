import 'package:asterfox/main.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'dart:io';

import 'package:asterfox/util/config_file.dart';

class SettingsData {
  static late ConfigFile settings;
  static Future<void> init() async {
    settings = await ConfigFile(File("$localPath/settings.json"), {
      "theme": "light",
    }).load();
  }

  static Future<void> save() async {
    settings.save();
  }

  static Future<void> applySettings() async {
    if (AppTheme.themeNotifier.value != settings.getValue("theme") as String) AppTheme.themeNotifier.value = settings.getValue("theme") as String;
  }
}