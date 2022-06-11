import 'dart:async';
import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/data/settings_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/audio_source/youtube_music_data.dart';
import 'package:asterfox/music/music_downloader.dart';
import 'package:asterfox/utils/youtube_music_utils.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_app/utils/in_app_notification/notification_data.dart';

import '../screens/home_screen.dart';

class HomeScreenMusicManager {
  static Future<void> addSong(String key, {String? youtubeId, MusicData? musicData}) async {
    assert(youtubeId != null || musicData != null);
    if (SettingsData.getValue(key: "auto_download")) {
      final completer = Completer();
      downloadProgress[key] = ValueNotifier<int>(0);
      HomeScreen.homeNotification.pushNotification(
        NotificationData(
            child: ValueListenableBuilder<int>(
              valueListenable: downloadProgress[key]!,
              builder: (_, percentage, __) => Column(
                children: [
                  const Text("自動ダウンロード中"),
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
              MusicData song;
              if (youtubeId != null) {
                song = (await YouTubeMusicUtils.getYouTubeAudio(youtubeId, key))!;
              } else {
                song = musicData!;
              }

              await song.save();
              await musicManager.add(song);
              completer.complete();
            }
        ),
      );
      return completer.future;
    }

    // <normal add>

    final completer = Completer();
    HomeScreen.homeNotification.pushNotification(
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
              MusicData song;
              if (youtubeId != null) {
                song = (await YouTubeMusicUtils.getYouTubeAudio(youtubeId, key))!;
              } else {
                song = musicData!;
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
    await addSong(const Uuid().v4(), youtubeId: list.first.id.value);
  }

  /// Download a song with progress indicator notification
  static Future<void> download(MusicData song, ) async {
    final completer = Completer();
    downloadProgress[song.key] = ValueNotifier<int>(0);
    HomeScreen.homeNotification.pushNotification(
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