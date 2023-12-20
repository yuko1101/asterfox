import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/settings_data.dart';
import '../../utils/color_utils.dart';
import 'extra_colors.dart';
import 'theme_details.dart';
import 'theme_options.dart';

class AppTheme {
  static ValueNotifier<ThemeData> themeNotifier =
      ValueNotifier<ThemeData>(themes[1]);

  static List<ThemeData> themes = [
    // light
    ThemeData(
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(
        color: Colors.white,
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
        ),
      ),
      backgroundColor: Colors.white,
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      extensions: <ThemeExtension<dynamic>>[
        ThemeDetails(
          name: "light",
        ),
        ExtraColors(
          primary: getGrey(0),
          secondary: getGrey(45),
          tertiary: getGrey(100),
          quaternary: getGrey(150),
          themeColor: getGrey(255),
        ),
        ThemeOptions(shadow: ShadowLevel.high),
      ],
    ),
    // dark
    ThemeData(
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        color: getMaterialColor(Colors.black87),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
        ),
      ),
      backgroundColor: getGrey(20),
      scaffoldBackgroundColor: getGrey(20),
      dialogBackgroundColor: getGrey(20),
      focusColor: Colors.orange,
      drawerTheme: DrawerThemeData(
        backgroundColor: getGrey(20),
      ),
      extensions: <ThemeExtension<dynamic>>[
        ThemeDetails(
          name: "dark",
        ),
        ExtraColors(
          primary: getGrey(255),
          secondary: getGrey(200),
          tertiary: getGrey(100),
          quaternary: getGrey(30),
          themeColor: getGrey(0),
        ),
        ThemeOptions(shadow: ShadowLevel.low),
      ],
    )
  ];

  static Future<void> setTheme(String name) async {
    if (!themes.any((theme) => theme.themeDetails.name == name)) {
      throw Exception("theme not found");
    }
    themeNotifier.value = getTheme(name);
    SettingsData.settings.set(key: "theme", value: name);
    await SettingsData.save();
  }

  static ThemeData getTheme(String name) {
    return themes.firstWhere((theme) => theme.themeDetails.name == name);
  }
}

extension ThemeExtensionGetter on ThemeData {
  ExtraColors get extraColors =>
      extensions.values.firstWhere((e) => e is ExtraColors) as ExtraColors;
  ThemeOptions get themeOptions =>
      extensions.values.firstWhere((e) => e is ThemeOptions) as ThemeOptions;
  ThemeDetails get themeDetails =>
      extensions.values.firstWhere((e) => e is ThemeDetails) as ThemeDetails;
}
