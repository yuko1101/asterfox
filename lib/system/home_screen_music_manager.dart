import 'dart:async';

import 'package:asterfox/data/song_history_data.dart';
import 'package:asterfox/music/utils/muisc_url_utils.dart';
import 'package:easy_app/utils/in_app_notification/notification_data.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../data/custom_colors.dart';
import '../data/local_musics_data.dart';
import '../data/settings_data.dart';
import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/music_downloader.dart';
import '../screens/home_screen.dart';
import '../music/utils/youtube_music_utils.dart';
import 'exceptions/network_exception.dart';

class HomeScreenMusicManager {
  static Future<void> addSong({
    required String key,
    String? youtubeId,
    MusicData? musicData,
    String? mediaUrl,
  }) async {
    assert(youtubeId != null || musicData != null || mediaUrl != null);
    if (musicData != null) assert(musicData.isTemporary == true);

    // the auto downloader works only for remote music
    final bool autoDownloadEnabled =
        SettingsData.getValue(key: "autoDownload") &&
            (!LocalMusicsData.isInstalled(
                audioId: youtubeId ??
                    (mediaUrl != null
                        ? MusicUrlUtils.getAudioIdFromUrl(mediaUrl)
                        : null),
                song: musicData));

    final completer = Completer();

    if (autoDownloadEnabled) downloadProgress[key] = ValueNotifier<int>(0);

    final Widget notification = autoDownloadEnabled
        ? ValueListenableBuilder<int>(
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
                    backgroundColor:
                        CustomColors.getColor("accent").withOpacity(0.1),
                  ),
                ),
              ],
            ),
          )
        : Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(),
              ),
              const SizedBox(width: 8),
              Text(
                  Language.getText("loading_songs").replaceAll("{count}", "1")),
            ],
          );

    HomeScreen.homeNotification.pushNotification(
      NotificationData(
        child: notification,
        progress: () async {
          MusicData song;
          if (musicData == null) {
            if (youtubeId != null) {
              try {
                song = await YouTubeMusicUtils.getYouTubeAudio(
                  videoId: youtubeId,
                  key: key,
                  isTemporary: false,
                );
              } on VideoUnplayableException {
                Fluttertoast.showToast(
                    msg: Language.getText("song_unplayable"));
                return;
              } on NetworkException {
                Fluttertoast.showToast(
                    msg: Language.getText("network_not_accessible"));
                return;
              }
            } else {
              try {
                song = await MusicUrlUtils.createMusicDataFromUrl(
                    mediaUrl: mediaUrl!, key: key, isTemporary: false);
              } on VideoUnplayableException {
                Fluttertoast.showToast(
                    msg: Language.getText("song_unplayable"));
                return;
              } on NetworkException {
                Fluttertoast.showToast(
                    msg: Language.getText("network_not_accessible"));
                return;
              }
            }
          } else {
            song = musicData.renew(key: key, isTemporary: false);
          }

          if (autoDownloadEnabled) {
            try {
              await song.download();
            } on NetworkException {
              Fluttertoast.showToast(
                  msg: Language.getText("network_not_accessible"));
              return;
            }
          }
          await musicManager.add(song);
          completer.complete();
        },
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

    final bool autoDownloadEnabled = SettingsData.getValue(key: "autoDownload");

    final completer = Completer();

    ValueNotifier<int>? progress;
    ValueNotifier<bool>? isDownloadMode;
    if (autoDownloadEnabled) {
      progress = ValueNotifier<int>(0);
      isDownloadMode = ValueNotifier<bool>(false);
    }

    final Widget notification = autoDownloadEnabled
        ? ValueListenableBuilder<int>(
            valueListenable: progress!,
            builder: (_, i, __) => Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: isDownloadMode!,
                  builder: (_, value, __) {
                    if (!value) {
                      return Text(Language.getText("loading_songs")
                          .replaceAll("{count}", "$count"));
                    }
                    return Text(
                        "${Language.getText("downloading_automatically")} ($i/$count)");
                  },
                ),
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: i / count,
                    color: CustomColors.getColor("accent"),
                    backgroundColor:
                        CustomColors.getColor("accent").withOpacity(0.1),
                  ),
                ),
              ],
            ),
          )
        : Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(),
              ),
              const SizedBox(width: 8),
              Text(Language.getText("loading_songs")
                  .replaceAll("{count}", "$count")),
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
              songs = (await YouTubeMusicUtils.getPlaylist(
                playlistId: youtubePlaylist!,
                isTemporary: false,
              ))
                  .first;
            } on NetworkException {
              Fluttertoast.showToast(
                  msg: Language.getText("network_not_accessible"));
              return;
            }
          }

          if (autoDownloadEnabled) {
            isDownloadMode!.value = true;
            try {
              await Future.wait(songs.map((song) async {
                await song.download(storeToJSON: false);
                progress!.value = progress.value + 1;
              }));
              for (final song in songs) {
                if (song.isStored) continue;
                await LocalMusicsData.store(song);
              }
            } on NetworkException {
              Fluttertoast.showToast(
                  msg: Language.getText("network_not_accessible"));
              completer.complete();
              return;
            }
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
      HomeScreen.homeNotification.pushNotification(NotificationData(
        child: Text(Language.getText("invalid_url")),
      ));
      return;
    }
    await addSong(key: const Uuid().v4(), youtubeId: id.value);
  }

  static final RegExp playlistRegex =
      RegExp(r"^https?://(www.)?youtube.com/playlist\?((.+=.+&)*)list=([^&]+)");
  static Future<bool> loadPlaylist(String text) async {
    if (!playlistRegex.hasMatch(text)) {
      return false;
    }
    final match = playlistRegex.firstMatch(text)!;
    final listId = match.group(4)!;
    final yt = YoutubeExplode();
    final playlist = await yt.playlists.get(listId);
    if (playlist.videoCount == null || playlist.videoCount == 0) {
      HomeScreen.homeNotification.pushNotification(NotificationData(
        child: Text(Language.getText("external_playlist_empty")),
      ));
      return true;
    }
    await HomeScreenMusicManager.addSongs(
      count: playlist.videoCount!,
      youtubePlaylist: listId,
    );
    return true;
  }

  /// Download a song with progress indicator notification
  static Future<void> download(
    MusicData song,
  ) async {
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
                  backgroundColor:
                      CustomColors.getColor("accent").withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        progress: () async {
          try {
            await MusicDownloader.download(song);
          } on NetworkException {
            Fluttertoast.showToast(
                msg: Language.getText("network_not_accessible"));
            return;
          }
          completer.complete();
        },
      ),
    );
    return completer.future;
  }
}
