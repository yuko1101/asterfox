import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'home_screen_music_manager.dart';

class SharingIntent {
  static Future<void> addSong(
      String? text, bool initial, BuildContext context) async {
    // Fluttertoast.showToast(msg: "${initial ? "Initial " : ""}Loading from $text");
    if (text == null) return;
    HomeScreenMusicManager.addSongBySearch(
      query: text,
      localizations: AppLocalizations.of(context)!,
    );
  }
}
