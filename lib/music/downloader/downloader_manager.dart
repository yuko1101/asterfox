import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/local_musics_data.dart';
import '../../system/exceptions/song_already_installed_exception.dart';
import '../../system/exceptions/song_already_installing_exception.dart';
import '../../system/firebase/cloud_firestore.dart';
import '../../utils/async_utils.dart';
import '../../utils/network_utils.dart';
import '../../utils/pair.dart';
import '../music_data/music_data.dart';
import 'audio_downloader.dart';
import 'image_downloader.dart';

class DownloadManager {
  static final Map<String, Pair<ValueNotifier<bool>, ValueNotifier<int>>>
      _downloadingState = {};

  static final ValueNotifier<List<String>> downloadingNotifier =
      ValueNotifier([]);

  static Future<void> download(MusicData song) async {
    final String downloadId = song.audioId;

    if (song.isInstalled) {
      throw SongAlreadyInstalledException();
    }
    if (isDownloading(downloadId)) {
      throw SongAlreadyInstallingException();
    }

    NetworkUtils.check();

    _downloadStarted(downloadId);
    final percentage = _getNotifiers(downloadId).second;
    final bytesNotifier = ValueNotifier<Pair<int, int>>(Pair(0, 1));
    bytesNotifier.addListener(() {
      final bytes = bytesNotifier.value;
      if (bytes.second > 0) {
        percentage.value = bytes.first * 100 ~/ bytes.second;
      }
    });

    try {
      if (!await song.isAudioUrlAvailable()) await song.refreshAudioUrl();

      await ImageDownloader.download(song);
      final audioInfo = await AudioDownloader.download(
        song,
        bytesNotifier: bytesNotifier,
      );
      // The info file marks the song as installed, so it is written last.
      await audioInfo.save(song.audioInfoPath);
    } catch (_) {
      // A half-written audio would otherwise be played as if it were complete
      // the next time, and be in the way of downloading it again.
      final audio = File(song.audioSavePath);
      if (audio.existsSync()) await audio.delete();
      rethrow;
    } finally {
      bytesNotifier.dispose();
      _downloadFinished(downloadId);
    }

    song.size = await Directory(song.directoryPath).length;
    // if the song has already stored, update file size property and save.
    if (song.isStored) {
      await LocalMusicsData.save(song);
      await CloudFirestoreManager.addOrUpdateSongs([song]);
    }
  }

  static Pair<ReadonlyValueNotifier<bool>, ReadonlyValueNotifier<int>>
      getNotifiers(String key) {
    final pair = _getNotifiers(key);
    return Pair(pair.first.toReadonly(), pair.second.toReadonly());
  }

  static Pair<ValueNotifier<bool>, ValueNotifier<int>> _getNotifiers(
      String key) {
    return _downloadingState.putIfAbsent(
        key, () => Pair(ValueNotifier(false), ValueNotifier(0)));
  }

  static bool isDownloading(String key) =>
      _downloadingState[key]?.first.value ?? false;

  static void _downloadStarted(String key) {
    _getNotifiers(key).first.value = true;
    downloadingNotifier.value = [...downloadingNotifier.value, key];
  }

  static void _downloadFinished(String key) {
    _downloadingState.remove(key);
    downloadingNotifier.value = [...downloadingNotifier.value]..remove(key);
  }
}

extension DirectoryLengthExtension on Directory {
  /// The total size of the files directly in this directory, in bytes.
  Future<int> get length async {
    var total = 0;
    await for (final entity in list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
