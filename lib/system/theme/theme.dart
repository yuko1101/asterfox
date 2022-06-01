import 'package:asterfox/config/settings_data.dart';
import 'package:asterfox/system/theme/extra_colors.dart';
import 'package:asterfox/system/theme/theme_options.dart';
import 'package:asterfox/util/color_util.dart';
import 'package:flutter/material.dart';

class AppTheme {

  static ValueNotifier<String> themeNotifier = ValueNotifier<String>("light");

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(color: Colors.white, foregroundColor: Colors.black),
    backgroundColor: Colors.white,

    extensions: <ThemeExtension<dynamic>>[
      ExtraColors(
          primary: getGrey(0),
          secondary: getGrey(45),
          tertiary: getGrey(100),
          quaternary: getGrey(150),
          themeColor: getGrey(255)
      ),
      ThemeOptions(isShadowed: ShadowLevel.high)
    ]
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,

    appBarTheme: AppBarTheme(color: getMaterialColor(Colors.black87)),
    backgroundColor: getGrey(20),
    scaffoldBackgroundColor: getGrey(20),
    dialogBackgroundColor: getGrey(20),
    focusColor: Colors.orange,

    extensions: <ThemeExtension<dynamic>>[
      ExtraColors(
        primary: getGrey(255),
        secondary: getGrey(200),
        tertiary: getGrey(100),
        quaternary: getGrey(30),
        themeColor: getGrey(0),
      ),
      ThemeOptions(isShadowed: ShadowLevel.low)
    ]

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

extension ThemeExtensionGetter on ThemeData {
  ExtraColors get extraColors => extensions.values.firstWhere((e) => e is ExtraColors) as ExtraColors;
  ThemeOptions get themeOptions => extensions.values.firstWhere((e) => e is ThemeOptions) as ThemeOptions;
}