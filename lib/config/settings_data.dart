import 'package:asterfox/main.dart';

import '../util/config_file.dart';
import 'dart:io';

class SettingsData {
  static late ConfigFile settings;
  static Future<void> init() async {
    settings = await ConfigFile(File("$localPath/settings.json"), {

    }).load();
  }

  static Future<void> save() async {
    settings.save();
  }
}