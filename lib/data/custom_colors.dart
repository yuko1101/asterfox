import 'dart:io';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/utils/config_file.dart';
import 'package:flutter/material.dart';

class CustomColors {
  static late ConfigFile data;

  static Future<void> load() async {
    final Map<String, int> defaultColorData = {
      "accent": Colors.orange.value
    };
    data = await ConfigFile(File("${EasyApp.localPath}/custom_colors.json"), defaultColorData).load();

  }

  static Color getColor(String name) {
    return Color(data.getValue(name) as int);
  }
}