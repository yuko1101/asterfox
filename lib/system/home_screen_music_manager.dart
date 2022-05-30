import 'dart:async';
import 'package:asterfox/config/custom_colors.dart';
import 'package:asterfox/config/settings_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/audio_source/youtube_music_data.dart';
import 'package:asterfox/music/music_downloader.dart';
import 'package:asterfox/screen/screens/home_screen.dart';
import 'package:asterfox/util/in_app_notification/notification_data.dart';
import 'package:asterfox/util/youtube_music_utils.dart';
import 'package:flutter/material.dart';

class HomeScreenMusicManager {
  static Future<void> addSongByID(String id) async {
    final completer = Completer();
    homeNotification.pushNotification(
        NotificationData(
            child: Row(
              children: const [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator()
                ),
                SizedBox(width: 8),
                Text("1曲を読み込み中"),
              ],
            ),
            progress: () async {
              final YouTubeMusicData song = (await YouTubeMusicUtils.getYouTubeAudio(id))!;
              if (SettingsData.getValue(key: "auto_download")) {
                await download(song);
              }
              await musicManager.add(song);
              completer.complete();
            }
        )
    );
    return completer.future;
  }
  static Future<void> addSongBySearch(String query) async {
    final list = await YouTubeMusicUtils.searchYouTubeVideo(query);
    await addSongByID(list.first.id.value);
  }

  /// Download a song with progress indicator notification
  static Future<void> download(MusicData song) async {
    final completer = Completer();
    downloadProgress[song.key] = ValueNotifier<int>(0);
    homeNotification.pushNotification(
      NotificationData(
          child: ValueListenableBuilder<int>(
            valueListenable: downloadProgress[song.key]!,
            builder: (_, percentage, __) => Column(
              children: [
                const Text("ダウンロード中"),
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: percentage / 100,
                    color: CustomColors.getColor("accent"),
                    backgroundColor: CustomColors.getColor("accent").withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
          progress: () async {
            await MusicDownloader.download(song);
            completer.complete();
          }
       ),
    );
    return completer.future;
  }
}