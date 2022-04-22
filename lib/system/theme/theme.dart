import 'package:asterfox/config/settings_data.dart';
import 'package:asterfox/util/color_util.dart';
import 'package:flutter/material.dart';

class AppTheme {

  static ValueNotifier<String> themeNotifier = ValueNotifier<String>("light");

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(color: Colors.white, foregroundColor: Colors.black),
    backgroundColor: Colors.white,
    textTheme: TextTheme(
      headline1: const TextStyle(color: Colors.black), // bright

      headline3: TextStyle(color: getGrey(45)), // middle
      headline5: TextStyle(color: getGrey(255))
    )
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,

    appBarTheme: AppBarTheme(color: getMaterialColor(Colors.black87)),
    backgroundColor: getGrey(20),
    scaffoldBackgroundColor: getGrey(20),
    dialogBackgroundColor: getGrey(20),
    textTheme: TextTheme(
      headline3: TextStyle(color: getGrey(200)), // middle
      headline4: TextStyle(color: getGrey(100)),
      headline5: TextStyle(color: getGrey(30))
    ),
    focusColor: Colors.orange,


  );

  static Map<String, ThemeData> themes = {
    "light": light,
    "dark": dark
  };

  static Map<String, String> themeNames = {
    "light": "ライト",
    "dark": "ダーク"
  };

  static Future<void> setTheme(String theme) async {
    if (!themes.keys.contains(theme)) throw Exception("theme not found");
    themeNotifier.value = theme;
    await SettingsData.settings.set(key: "theme", value: theme).save();
  }
}