import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../data/local_musics_data.dart';
import '../data/settings_data.dart';
import '../main.dart';
import '../music/music_data/music_data.dart';
import '../music/downloader/downloader_manager.dart';
import '../music/utils/music_data_utils.dart';
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
    String? audioId,
    MusicData<CachingDisabled>? musicData,
    String? mediaUrl,
  }) async {
    assert(audioId != null || musicData != null || mediaUrl != null);

    audioId = MusicDataUtils.getAudioId(
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
            ? l10n.value.downloading_automatically
            : l10n.value.loading_songs(1)),
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
          MusicData<CachingEnabled> song;
          try {
            song = await MusicData.get(
              musicData: musicData,
              audioId: audioId,
              caching: CachingEnabled(key),
            );
          } on VideoUnplayableException {
            Fluttertoast.showToast(msg: l10n.value.song_unplayable);
            return;
          } on NetworkException {
            Fluttertoast.showToast(msg: l10n.value.network_not_accessible);
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
                msg: Text(l10n.value.song_unplayable),
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
    List<MusicData<CachingDisabled>>? musicDataList,
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
                ? l10n.value.downloading_automatically
                : l10n.value.loading_songs(max),
          ),
        ),
        maxProgressListenable: maxProgressNotifier,
        progressListenable: progressNotifier,
        errorListNotifier: errorListNotifier,
        icon: const Icon(Icons.queue_music),
        future: () async {
          List<MusicData<CachingEnabled>> songs = [];

          final songStream = MusicData.getListWithCaching(
            musicDataList: musicDataList,
            mediaUrlList: mediaUrlList,
            youtubePlaylist: youtubePlaylist,
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

  /// Download a song with progress indicator notification
  static Future<void> download(MusicData song) async {
    final completer = Completer();

    final ValueNotifier<List<ResultFailedReason>> errorListNotifier =
        ValueNotifier([]);

    HomeScreen.processNotificationList.push(
      ProcessNotificationData(
        title: Text(
          "${l10n.value.downloading}${song.size != null ? " - ${_formatBytes(song.size!, 1)}" : ""}",
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
