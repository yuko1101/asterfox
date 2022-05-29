import 'dart:async';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/youtube_music_data.dart';
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
}