import 'dart:async';
import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/data/settings_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/audio_source/youtube_music_data.dart';
import 'package:asterfox/music/music_downloader.dart';
import 'package:asterfox/utils/youtube_music_utils.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_app/utils/in_app_notification/notification_data.dart';

import '../screens/home_screen.dart';

class HomeScreenMusicManager {
  static Future<void> addSong({required String key, String? youtubeId, MusicData? musicData}) async {
    assert(youtubeId != null || musicData != null);

    // the auto downloader works only for remote music
    final bool autoDownload = SettingsData.getValue(key: "auto_download") && (!LocalMusicsData.isSaved(audioId: youtubeId, song: musicData));

    final completer = Completer();

    if (autoDownload) downloadProgress[key] = ValueNotifier<int>(0);

    final Widget notification = autoDownload ? ValueListenableBuilder<int>(
      valueListenable: downloadProgress[key]!,
      builder: (_, percentage, __) => Column(
        children: [
          Text(Language.getText("downloading_automatically")),
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
    ) : Row(
      children: [
        const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator()
        ),
        const SizedBox(width: 8),
        Text(Language.getText("loading_songs").replaceAll("{count}", "1")),
      ],
    );

    HomeScreen.homeNotification.pushNotification(
      NotificationData(
          child: notification,
          progress: () async {
            MusicData song;
            if (youtubeId != null) {
              song = (await YouTubeMusicUtils.getYouTubeAudio(videoId: youtubeId, key: key))!;
            } else {
              song = musicData!;
            }

            if (autoDownload) await song.save();
            await musicManager.add(song);
            completer.complete();
          }
      ),
    );
    return completer.future;
  }

  static Future<void> addSongs({
    required int count,
    List<MusicData>? musicDataList,
    String? youtubePlaylist,
  }) async {
    assert(count > 0);
    assert(musicDataList != null || youtubePlaylist != null);

    final bool autoDownload = SettingsData.getValue(key: "auto_download");

    final completer = Completer();

    ValueNotifier<int>? progress;
    ValueNotifier<bool>? isDownloadMode;
    if (autoDownload) {
      progress = ValueNotifier<int>(0);
      isDownloadMode = ValueNotifier<bool>(false);
    }

    final Widget notification = autoDownload ? ValueListenableBuilder<int>(
      valueListenable: progress!,
      builder: (_, i, __) => Column(
        children: [
          ValueListenableBuilder<bool>(
              valueListenable: isDownloadMode!,
              builder: (_, value, __) {
                if (!value) {
                  return Text(Language.getText("loading_songs").replaceAll("{count}", "$count"));
                }
                return Text("${Language.getText("downloading_automatically")} ($i/$count)");
              }
          ),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              minHeight: 8,
              value: i / count,
              color: CustomColors.getColor("accent"),
              backgroundColor: CustomColors.getColor("accent").withOpacity(0.1),
            ),
          ),
        ],
      ),
    ) : Row(
      children: [
        const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator()
        ),
        const SizedBox(width: 8),
        Text(Language.getText("loading_songs").replaceAll("{count}", "$count")),
      ],
    );

    HomeScreen.homeNotification.pushNotification(
        NotificationData(
          child: notification,
          progress: () async {
            List<MusicData> songs;
            if (musicDataList != null) {
              songs = musicDataList;
            } else {
              songs = (await YouTubeMusicUtils.getPlaylist(playlistId: youtubePlaylist!)).first;
            }

            if (autoDownload) {
              isDownloadMode!.value = true;
              await Future.wait(songs.map((song) async {
                await song.save(saveToJSON: false);
                progress!.value = progress.value + 1;
              }));
              for (final song in songs) {
                if (song.isSaved) continue;
                await LocalMusicsData.save(song);
              }
            }
            for (final song in songs) {
              song.loadLocal();
            }
            await musicManager.addAll(songs);
            completer.complete();
          },
        ),
    );

  }

  static Future<void> addSongBySearch(String query) async {
    final list = await YouTubeMusicUtils.searchYouTubeVideo(query);
    await addSong(key: const Uuid().v4(), youtubeId: list.first.id.value);
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
                Text(Language.getText("downloading")),
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