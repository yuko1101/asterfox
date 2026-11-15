import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide MusicData;

import '../data/local_musics_data.dart';
import '../data/settings_data.dart';
import '../data/song_history_data.dart';
import '../main.dart';
import '../music/music_data/music_data.dart';
import '../music/downloader/downloader_manager.dart';
import '../music/utils/music_data_utils.dart';
import '../screens/home_screen.dart';
import '../utils/async_utils.dart';
import '../utils/result.dart';
import '../widget/process_notifications/process_notification_widget.dart';
import '../widget/toast/toast_manager.dart';
import 'exceptions/network_exception.dart';

class HomeScreenMusicManager {
  /// Loads a song and adds it to the queue, showing the progress of it. The
  /// returned future ends when the song has been added or has failed to.
  static Future<void> addSong({
    required CachingEnabled caching,
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

    final songTitleNotifier = ValueNotifier<String?>(null);
    final errorListNotifier = ValueNotifier<List<ResultFailedReason>>([]);
    void addError(ResultFailedReason reason) =>
        errorListNotifier.value = [...errorListNotifier.value, reason];

    await HomeScreen.processNotificationList.push(
      ProcessNotificationData(
        title: Text(autoDownload
            ? l10n.value.downloading_automatically
            : l10n.value.loading_songs(1)),
        description: ValueListenableBuilder<String?>(
          valueListenable: songTitleNotifier,
          builder: (context, value, child) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Text(value ?? ""),
          ),
        ),
        icon: const Icon(Icons.music_note),
        progressInPercentage: true,
        maxProgress: 100,
        progressListenable: DownloadManager.getNotifiers(audioId).second,
        errorListNotifier: errorListNotifier,
        future: () async {
          try {
            final MusicData<CachingEnabled> song = musicData != null
                ? musicData.renew(caching: caching)
                : await MusicData.getByAudioId(
                    audioId: audioId!, caching: caching);
            songTitleNotifier.value = song.title;

            if (autoDownload) {
              final result = await song.download();
              if (result.status == ResultStatus.failed) {
                addError(result.getReason());
                ToastManager.showSimpleToast(
                  msg: Text(l10n.value.song_unplayable),
                  icon: const Icon(Icons.error_outline, color: Colors.red),
                );
              }
            }
            await musicManager.add(song);
          } on VideoUnplayableException {
            Fluttertoast.showToast(msg: l10n.value.song_unplayable);
          } on NetworkException {
            Fluttertoast.showToast(msg: l10n.value.network_not_accessible);
          } on Exception catch (e) {
            addError(_reasonOf(e));
          }
        }(),
      ),
    );
  }

  /// Adds [musicDataList] to the queue, downloading them first when the auto
  /// download is on.
  static Future<void> addSongs({
    required List<MusicData<CachingDisabled>> musicDataList,
  }) async {
    if (musicDataList.isEmpty) return;

    final bool autoDownloadEnabled = SettingsData.getValue(key: "autoDownload");

    final downloadModeNotifier = ValueNotifier<bool>(false);
    final progressNotifier = ValueNotifier<int>(0);
    final maxProgressNotifier = ValueNotifier<int>(musicDataList.length);
    final errorListNotifier = ValueNotifier<List<ResultFailedReason>>([]);
    void addError(ResultFailedReason reason) =>
        errorListNotifier.value = [...errorListNotifier.value, reason];

    await HomeScreen.processNotificationList.push(
      ProcessNotificationData(
        title: ValueListenableBuilder<bool>(
          valueListenable: downloadModeNotifier,
          builder: (context, isDownloadMode, child) => Text(
            isDownloadMode
                ? l10n.value.downloading_automatically
                : l10n.value.loading_songs(musicDataList.length),
          ),
        ),
        maxProgressListenable: maxProgressNotifier,
        progressListenable: progressNotifier,
        errorListNotifier: errorListNotifier,
        icon: const Icon(Icons.queue_music),
        future: () async {
          try {
            final songs = [
              for (final musicData in musicDataList)
                musicData.renew(caching: CachingEnabled.random()),
            ];
            progressNotifier.value = songs.length;

            if (autoDownloadEnabled) {
              final toDownload = songs.where((song) => !song.isInstalled);
              downloadModeNotifier.value = true;
              progressNotifier.value = 0;
              maxProgressNotifier.value = toDownload.length;

              final asyncCore = AsyncCore<Result<void>>(limit: 10);
              await Future.wait(toDownload.map((song) async {
                final result = await asyncCore.run(song.download);
                if (result.status == ResultStatus.failed) {
                  addError(result.getReason());
                }
                progressNotifier.value++;
              }));
            }
            await musicManager.addAll(songs);
          } on Exception catch (e) {
            addError(_reasonOf(e));
          }
        }(),
      ),
    );
  }

  /// Download a song with progress indicator notification
  static Future<void> download(MusicData song) async {
    final errorListNotifier = ValueNotifier<List<ResultFailedReason>>([]);

    await HomeScreen.processNotificationList.push(
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
            errorListNotifier.value = [result.getReason()];
          }
        }(),
      ),
    );
  }

  static ResultFailedReason _reasonOf(Exception e) => ResultFailedReason(
        cause: e,
        title: l10n.value.something_went_wrong,
        description: e.toString(),
      );
}

String _formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}
