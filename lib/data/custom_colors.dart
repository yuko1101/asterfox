import 'dart:io';

import 'package:flutter/material.dart';

import '../main.dart';
import '../utils/config_file.dart';

class CustomColors {
  static late ConfigFile data;

  static Future<void> load() async {
    final Map<String, int> defaultColorData = {"accent": Colors.orange.value};
    data = await ConfigFile(
            File("$localPath/custom_colors.json"), defaultColorData)
        .load();
  }

  static Color getColor(String name) {
    return Color(data.getValue(name) as int);
  }
}
