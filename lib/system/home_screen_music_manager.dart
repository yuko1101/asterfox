import 'dart:async';
import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/data/settings_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/music_downloader.dart';
import 'package:asterfox/system/exceptions/network_exception.dart';
import 'package:asterfox/utils/extensions.dart';
import 'package:asterfox/utils/youtube_music_utils.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_app/utils/in_app_notification/notification_data.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../screens/home_screen.dart';
import 'exceptions/local_song_not_found_exception.dart';

class HomeScreenMusicManager {
  static Future<void> addSong({required String key, String? youtubeId, MusicData? musicData}) async {
    assert(youtubeId != null || musicData != null);

    // the auto downloader works only for remote music
    final bool autoDownloadEnabled = SettingsData.getValue(key: "auto_download") && (!LocalMusicsData.isSaved(audioId: youtubeId, song: musicData));

    final completer = Completer();

    if (autoDownloadEnabled) downloadProgress[key] = ValueNotifier<int>(0);

    final Widget notification = autoDownloadEnabled ? ValueListenableBuilder<int>(
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
              try {
                song = (await YouTubeMusicUtils.getYouTubeAudio(videoId: youtubeId, key: key));
              } on VideoUnplayableException {
                Fluttertoast.showToast(msg: Language.getText("song_unplayable"));
                return;
              } on LocalSongNotFoundException {
                // TODO: multi-language
                Fluttertoast.showToast(msg: "Local song not found");
                return;
              } on NetworkException {
                Fluttertoast.showToast(msg: Language.getText("network_not_accessible"));
                return;
              }
            } else {
              song = musicData!;
            }

            if (autoDownloadEnabled) await song.save();
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

    final bool autoDownloadEnabled = SettingsData.getValue(key: "auto_download");

    final completer = Completer();

    ValueNotifier<int>? progress;
    ValueNotifier<bool>? isDownloadMode;
    if (autoDownloadEnabled) {
      progress = ValueNotifier<int>(0);
      isDownloadMode = ValueNotifier<bool>(false);
    }

    final Widget notification = autoDownloadEnabled ? ValueListenableBuilder<int>(
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
              try {
                songs = (await YouTubeMusicUtils.getPlaylist(playlistId: youtubePlaylist!)).first;
              } on NetworkException {
                Fluttertoast.showToast(msg: Language.getText("network_not_accessible"));
                return;
              }
            }

            if (autoDownloadEnabled) {
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
    if (query.isUrl) {
      await loadFromUrl(query);
      return;
    }
    final list = await YouTubeMusicUtils.searchYouTubeVideo(query);
    await addSong(key: const Uuid().v4(), youtubeId: list.first.id.value);
  }

  static Future<void> loadFromUrl(String url) async {
    final isPlaylist = await loadPlaylist(url);
    if (isPlaylist) return;

    VideoId id;
    try {
      id = VideoId(url);
    } on ArgumentError {
      HomeScreen.homeNotification.pushNotification(
        NotificationData(
          child: Text(Language.getText("invalid_url")),
        )
      );
      return;
    }
    await addSong(key: const Uuid().v4(), youtubeId: id.value);
  }


  static final RegExp playlistRegex = RegExp(r"^https?://(www.)?youtube.com/playlist\?((.+=.+&)*)list=([^&]+)");
  static Future<bool> loadPlaylist(String text) async {
    if (!playlistRegex.hasMatch(text)) {
      return false;
    }
    final match = playlistRegex.firstMatch(text)!;
    final listId = match.group(4)!;
    final yt = YoutubeExplode();
    final playlist = await yt.playlists.get(listId);
    if (playlist.videoCount == null || playlist.videoCount == 0) {
      HomeScreen.homeNotification.pushNotification(
          NotificationData(
            child: Text(Language.getText("external_playlist_empty")),
          )
      );
      return true;
    }
    await HomeScreenMusicManager.addSongs(count: playlist.videoCount!, youtubePlaylist: listId);
    return true;
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