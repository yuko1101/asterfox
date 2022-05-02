import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../music/audio_source/youtube_audio.dart';
import '../screen/screens/home_screen.dart';
import '../util/in_app_notification/notification_data.dart';
import '../util/youtube_music_utils.dart';

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
              final YouTubeAudio song = (await YouTubeMusicUtils.getYouTubeAudio(id))!;
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