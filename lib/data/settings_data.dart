import 'dart:io';

import 'package:asterfox/main.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../system/firebase/cloud_firestore.dart';
import '../system/theme/theme.dart';

class SettingsData {
  static late ConfigFile settings;
  static const Map<String, dynamic> defaultData = {
    "theme": "dark",
    "autoDownload": false,
  };
  static Future<void> init() async {
    settings = await ConfigFile(
      File("${EasyApp.localPath}/settings.json"),
      defaultData,
    ).load();
  }

  static Future<void> save({bool upload = true}) async {
    await settings.save();
    if (shouldInitializeFirebase &&
        FirebaseAuth.instance.currentUser != null &&
        upload) {
      await CloudFirestoreManager.updateUserData();
    }
  }

  static Future<void> applySettings() async {
    if (AppTheme.themeNotifier.value.themeDetails.name !=
        getValue(key: "theme") as String) {
      AppTheme.themeNotifier.value =
          AppTheme.getTheme(getValue(key: "theme") as String);
    }
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
