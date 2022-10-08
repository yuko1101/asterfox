import 'dart:async';

import 'package:asterfox/data/song_history_data.dart';
import 'package:asterfox/music/utils/muisc_url_utils.dart';
import 'package:asterfox/widget/toast/toast_manager.dart';
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
import '../widget/notifiers_widget.dart';
import '../widget/process_notifications/process_notification_widget.dart';
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

    HomeScreen.processNotificationList.push(
      ProcessNotificationData(
        title: notification,
        icon: const Icon(Icons.music_note),
        future: () async {
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
        }(),
      ),
    );
    return completer.future;
  }

  static Future<void> addSongs({
    required int count,
    List<MusicData>? musicDataList,
    List<String>? mediaUrlList,
    String? youtubePlaylist,
  }) async {
    assert(count > 0);
    assert(musicDataList != null ||
        mediaUrlList != null ||
        youtubePlaylist != null);

    // playlist loading progress
    final String playlistProcessId = const Uuid().v4();
    YouTubeMusicUtils.playlistLoadingProgress[playlistProcessId] =
        ValueNotifier(0);
    final ValueNotifier<int> playlistLoadingProgress =
        YouTubeMusicUtils.playlistLoadingProgress[playlistProcessId]!;

    // auto download progress
    final bool autoDownloadEnabled = SettingsData.getValue(key: "autoDownload");

    final notificationCompleter = Completer();

    ValueNotifier<int>? downloadProgress = ValueNotifier<int>(0);
    ValueNotifier<bool>? isDownloadMode = ValueNotifier<bool>(false);

    final Widget notification = TripleNotifierWidget<int, int, bool>(
      notifier1: playlistLoadingProgress,
      notifier2: downloadProgress,
      notifier3: isDownloadMode,
      builder: (_, loaded, downloaded, downloadMode, __) => Column(
        children: [
          !downloadMode
              ? Text(Language.getText("loading_songs")
                  .replaceAll("{count}", "$count"))
              : Text(
                  "${Language.getText("downloading_automatically")} ($downloaded/$count)"),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (downloadMode ? downloaded : loaded) / count,
              color: CustomColors.getColor("accent"),
              backgroundColor: CustomColors.getColor("accent").withOpacity(0.1),
            ),
          ),
        ],
      ),
    );

    HomeScreen.processNotificationList.push(
      ProcessNotificationData(
        title: notification,
        icon: const Icon(Icons.queue_music),
        future: () async {
          List<MusicData> songs = [];
          if (musicDataList != null) {
            songs.addAll(musicDataList);
          }
          if (mediaUrlList != null) {
            List<MusicData> parsed;
            try {
              parsed = await Future.wait(
                mediaUrlList
                    .map((mediaUrl) => MusicUrlUtils.createMusicDataFromUrl(
                          mediaUrl: mediaUrl,
                          key: const Uuid().v4(),
                          isTemporary: false,
                        )),
              );
            } on NetworkException {
              Fluttertoast.showToast(
                  msg: Language.getText("network_not_accessible"));
              return;
            }

            songs.addAll(parsed);
          }
          if (youtubePlaylist != null) {
            try {
              songs.addAll((await YouTubeMusicUtils.getPlaylist(
                playlistId: youtubePlaylist,
                isTemporary: false,
                processId: playlistProcessId,
              ))
                  .first);
            } on NetworkException {
              Fluttertoast.showToast(
                  msg: Language.getText("network_not_accessible"));
              return;
            }
          }

          if (autoDownloadEnabled) {
            isDownloadMode.value = true;
            try {
              await Future.wait(songs.map((song) async {
                await song.download(storeToJSON: false);
                downloadProgress.value = downloadProgress.value + 1;
              }));
              for (final song in songs) {
                if (song.isStored) continue;
                await LocalMusicsData.store(song);
              }
            } on NetworkException {
              Fluttertoast.showToast(
                  msg: Language.getText("network_not_accessible"));
              notificationCompleter.complete();
              return;
            }
          }
          await musicManager.addAll(songs);
          notificationCompleter.complete();
        }(),
      ),
    );
  }

  static Future<void> addSongBySearch(String query,
      {BuildContext? context, ThemeData? theme}) async {
    if (query.isUrl) {
      await loadFromUrl(query, context: context, theme: theme);
      return;
    }
    final list = await YouTubeMusicUtils.searchYouTubeVideo(query);
    await addSong(key: const Uuid().v4(), youtubeId: list.first.id.value);
  }

  static Future<void> loadFromUrl(String url,
      {BuildContext? context, ThemeData? theme}) async {
    final isPlaylist = await loadPlaylist(url, context: context, theme: theme);
    if (isPlaylist) return;

    VideoId id;
    try {
      id = VideoId(url);
    } on ArgumentError {
      ToastManager.showSimpleToast(
        msg: Text(Language.getText("invalid_url")),
        icon: const Icon(
          Icons.wifi_off,
          color: Colors.red,
        ),
        context: context,
      );
      return;
    }
    await addSong(key: const Uuid().v4(), youtubeId: id.value);
  }

  static final RegExp playlistRegex =
      RegExp(r"^https?://(www.)?youtube.com/playlist\?((.+=.+&)*)list=([^&]+)");
  static Future<bool> loadPlaylist(String text,
      {BuildContext? context, ThemeData? theme}) async {
    if (!playlistRegex.hasMatch(text)) {
      return false;
    }
    final match = playlistRegex.firstMatch(text)!;
    final listId = match.group(4)!;
    final yt = YoutubeExplode();
    final playlist = await yt.playlists.get(listId);
    if (playlist.videoCount == null || playlist.videoCount == 0) {
      ToastManager.showSimpleToast(
        icon: const Icon(Icons.music_off_outlined, color: Colors.red),
        msg: Text(Language.getText("external_playlist_empty")),
        context: context,
        theme: theme,
      );
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
    HomeScreen.processNotificationList.push(
      ProcessNotificationData(
        title: ValueListenableBuilder<int>(
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
        icon: const Icon(Icons.download),
        future: () async {
          try {
            await MusicDownloader.download(song);
          } on NetworkException {
            Fluttertoast.showToast(
                msg: Language.getText("network_not_accessible"));
            return;
          }
          completer.complete();
        }(),
      ),
    );
    return completer.future;
  }
}
