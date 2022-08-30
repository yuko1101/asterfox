import 'dart:io';

import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';

class TemporaryData {
  static late ConfigFile data;

  static const Map<String, dynamic> defaultData = {};

  static Future<void> init() async {
    data = await ConfigFile(
      File("${EasyApp.localPath}/temporary_data.json"),
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
}
