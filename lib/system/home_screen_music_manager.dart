import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../data/local_musics_data.dart';
import '../data/settings_data.dart';
import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/music_downloader.dart';
import '../music/utils/music_url_utils.dart';
import '../screens/home_screen.dart';
import '../music/utils/youtube_music_utils.dart';
import '../utils/async_utils.dart';
import '../utils/result.dart';
import '../widget/notifiers_widget.dart';
import '../widget/process_notifications/process_notification_widget.dart';
import '../widget/toast/toast_manager.dart';
import 'exceptions/network_exception.dart';
import 'exceptions/unable_to_load_from_playlist_exception.dart';

class HomeScreenMusicManager {
  static Future<void> addSong({
    required String key,
    required AppLocalizations localizations,
    String? audioId,
    MusicData? musicData,
    String? mediaUrl,
  }) async {
    assert(audioId != null || musicData != null || mediaUrl != null);
    if (musicData != null) assert(musicData.isTemporary == true);

    audioId = MusicUrlUtils.getAudioId(
        audioId: audioId, mediaUrl: mediaUrl, musicData: musicData);

    // the auto downloader works only for remote music
    final bool autoDownload = SettingsData.getValue(key: "autoDownload") &&
        !LocalMusicsData.isInstalled(audioId: audioId);

    final completer = Completer();

    final ValueNotifier<String?> songTitleNotifier = ValueNotifier(null);
    final ValueNotifier<List<ResultFailedReason>> errorListNotifier =
        ValueNotifier<List<ResultFailedReason>>([]);
    HomeScreen.processNotificationList.push(
      ProcessNotificationData(
        title: Text(autoDownload
            ? localizations.downloading_automatically
            : localizations.loading_songs(1)),
        description: ValueListenableBuilder<String?>(
          valueListenable: songTitleNotifier,
          builder: (context, value, child) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Text(
              value ?? "",
            ),
          ),
        ),
        icon: const Icon(Icons.music_note),
        progressInPercentage: true,
        maxProgress: 100,
        progressListenable: DownloadManager.getNotifiers(audioId).second,
        errorListNotifier: errorListNotifier,
        future: () async {
          MusicData song;
          try {
            song = await MusicData.get(
              musicData: musicData,
              audioId: audioId,
              key: key,
              isTemporary: false,
            );
          } on VideoUnplayableException {
            Fluttertoast.showToast(msg: localizations.song_unplayable);
            return;
          } on NetworkException {
            Fluttertoast.showToast(msg: localizations.network_not_accessible);
            return;
          }
          songTitleNotifier.value = song.title;

          if (autoDownload) {
            final result = await song.download();
            if (result.status == ResultStatus.failed) {
              errorListNotifier.value = errorListNotifier.value.toList()
                ..add(result.getReason());

              // TODO: pass context
              ToastManager.showSimpleToast(
                msg: Text(localizations.song_unplayable),
                icon: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                ),
              );
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

    // auto download
    final bool autoDownloadEnabled = SettingsData.getValue(key: "autoDownload");

    // initialize notifiers
    final ValueNotifier<bool> downloadModeNotifier = ValueNotifier<bool>(false);
    final ValueNotifier<int> progressNotifier =
        YouTubeMusicUtils.playlistLoadingProgress[playlistProcessId]!;
    final ValueNotifier<int> maxProgressNotifier = ValueNotifier<int>(count);
    final ValueNotifier<List<ResultFailedReason>> errorListNotifier =
        ValueNotifier([]);

    await HomeScreen.processNotificationList.push(
      ProcessNotificationData(
        title: DoubleNotifierWidget<bool, int>(
          notifier1: downloadModeNotifier,
          notifier2: maxProgressNotifier,
          builder: (context, isDownloadMode, max, child) => Text(
            isDownloadMode
                ? AppLocalizations.of(context)!.downloading_automatically
                : AppLocalizations.of(context)!.loading_songs(max),
          ),
        ),
        maxProgressListenable: maxProgressNotifier,
        progressListenable: progressNotifier,
        errorListNotifier: errorListNotifier,
        icon: const Icon(Icons.queue_music),
        future: () async {
          List<MusicData> songs = [];

          final songStream = MusicData.getList(
            musicDataList: musicDataList,
            mediaUrlList: mediaUrlList,
            youtubePlaylist: youtubePlaylist,
            isTemporary: false,
            renew: false,
          );

          final completer = Completer();

          songStream.listen((song) {
            songs.add(song);
            progressNotifier.value = songs.length;
          }, onError: (e) {
            e as UnableToLoadFromPlaylistException;
            errorListNotifier.value = errorListNotifier.value.toList()
              ..add(
                ResultFailedReason(
                  cause: e,
                  title: e.title,
                  description: e.description,
                ),
              );
            maxProgressNotifier.value = maxProgressNotifier.value - 1;
          }, onDone: completer.complete);

          await completer.future;

          if (autoDownloadEnabled) {
            downloadModeNotifier.value = true;
            progressNotifier.value = 0;
            maxProgressNotifier.value = songs.length;

            final asyncCore = AsyncCore<Result<void>>(limit: 10);

            await Future.wait(songs.map((song) async {
              if (song.isInstalled) {
                maxProgressNotifier.value = maxProgressNotifier.value - 1;
                return;
              }
              final result = await asyncCore.run(song.download);
              if (result.status == ResultStatus.failed) {
                errorListNotifier.value = errorListNotifier.value.toList()
                  ..add(result.getReason());
              }
              progressNotifier.value = progressNotifier.value + 1;
            }));
          }
          await musicManager.addAll(songs);
        }(),
      ),
    );
  }

  static Future<void> addSongBySearch({
    required String query,
    required AppLocalizations localizations,
  }) async {
    if (query.isUrl) {
      await loadFromUrl(url: query, localizations: localizations);
      return;
    }
    final list = await YouTubeMusicUtils.searchYouTubeVideo(query);
    await addSong(
        key: const Uuid().v4(),
        audioId: list.first.id.value,
        localizations: localizations);
  }

  static Future<void> loadFromUrl({
    required String url,
    required AppLocalizations localizations,
  }) async {
    final isPlaylist =
        await loadPlaylist(url: url, localizations: localizations);
    if (isPlaylist) return;

    VideoId id;
    try {
      id = VideoId(url);
    } on ArgumentError {
      ToastManager.showSimpleToast(
        msg: Text(localizations.invalid_url),
        icon: const Icon(
          Icons.wifi_off,
          color: Colors.red,
        ),
      );
      return;
    }
    await addSong(
        key: const Uuid().v4(),
        audioId: id.value,
        localizations: localizations);
  }

  static final RegExp playlistRegex =
      RegExp(r"^https?://(www.)?youtube.com/playlist\?((.+=.+&)*)list=([^&]+)");
  static Future<bool> loadPlaylist({
    required String url,
    required AppLocalizations localizations,
  }) async {
    if (!playlistRegex.hasMatch(url)) {
      return false;
    }
    final match = playlistRegex.firstMatch(url)!;
    final listId = match.group(4)!;
    final yt = YoutubeExplode();
    final playlist = await yt.playlists.get(listId);
    if (playlist.videoCount == null || playlist.videoCount == 0) {
      ToastManager.showSimpleToast(
        icon: const Icon(Icons.music_off_outlined, color: Colors.red),
        msg: Text(localizations.external_playlist_empty),
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
    AppLocalizations localizations,
  ) async {
    final completer = Completer();

    final ValueNotifier<List<ResultFailedReason>> errorListNotifier =
        ValueNotifier([]);

    HomeScreen.processNotificationList.push(
      ProcessNotificationData(
        title: Text(
          "${localizations.downloading}${song.size != null ? " - ${_formatBytes(song.size!, 1)}" : ""}",
        ),
        description: Text(song.title),
        maxProgress: 100,
        progressInPercentage: true,
        progressListenable: DownloadManager.getNotifiers(song.audioId).second,
        errorListNotifier: errorListNotifier,
        icon: const Icon(Icons.download),
        future: () async {
          final result = await song.download();
          if (result.status == ResultStatus.failed) {
            errorListNotifier.value = errorListNotifier.value.toList()
              ..add(result.getReason());
          }
          completer.complete();
        }(),
      ),
    );
    return completer.future;
  }
}

String _formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}
