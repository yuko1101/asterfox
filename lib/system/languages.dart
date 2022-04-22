import 'dart:convert';
import 'dart:io';
import 'package:asterfox/config/settings_data.dart';
import 'package:flutter/services.dart' show rootBundle;

class Language {
  static final List<String> languages = [
    "ja_JP",
    "en_US",
  ];

  static late Map<String, dynamic> currentLanguage;

  static String getText(String key) {
    return currentLanguage[key] ?? "";
  }

  static Future<void> init() async {
    // final String locale = SettingsData.settings.has("language")
    //     ? SettingsData.settings.getValue("language") as String
    //     : Platform.localeName;
    final String locale = Platform.localeName;
    try {
      await loadLanguage(locale);
    } catch (e) {
      if (locale != "en_US") await loadLanguage("en_US");
    }
  }


  static Future<void> loadLanguage(String language) async {
    if (!languages.contains(language)) throw Exception("Language not found");
    final String content = await rootBundle.loadString("assets/lang/$language.json");
    final Map<String, dynamic> json = jsonDecode(content);
    currentLanguage = json;
    // await SettingsData.settings.set(key: "language", value: language).save();
  }
}