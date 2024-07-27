import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    final notifiers = _getNotifiers(downloadId);

    if (!await song.isAudioUrlAvailable()) await song.refreshAudioUrl();

    // download
    await ImageDownloader.download(song);

    final bytesNotifier = ValueNotifier<Pair<int, int>>(Pair(0, 0));
    bytesNotifier.addListener(() {
      notifiers.second.value =
          bytesNotifier.value.first * 100 ~/ bytesNotifier.value.second;
    });
    final audioInfo = await AudioDownloader.download(
      song,
      bytesNotifier: bytesNotifier,
    );
    bytesNotifier.dispose();

    audioInfo.save(song.audioInfoPath);

    // save file size
    song.size = await Directory(song.directoryPath).length;
    // if the song has already stored, update file size property and save.
    if (song.isStored) {
      await LocalMusicsData.localMusicData
          .get([song.audioId])
          .set(key: "size", value: song.size)
          .save(compact: LocalMusicsData.compact);
      await CloudFirestoreManager.addOrUpdateSongs([song]);
    }

    _downloadFinished(downloadId);
  }

  static Pair<ReadonlyValueNotifier<bool>, ReadonlyValueNotifier<int>>
      getNotifiers(String key) {
    final pair = _getNotifiers(key);
    return Pair(pair.first.toReadonly(), pair.second.toReadonly());
  }

  static Pair<ValueNotifier<bool>, ValueNotifier<int>> _getNotifiers(
      String key) {
    if (!_downloadingState.containsKey(key)) {
      _downloadingState
          .addAll({key: Pair(ValueNotifier(false), ValueNotifier(0))});
    }
    return _downloadingState[key]!;
  }

  static bool isDownloading(String key) {
    return _downloadingState.containsKey(key) &&
        _downloadingState[key]!.first.value;
  }

  static _downloadStarted(String key) {
    final notifiers = _getNotifiers(key);
    notifiers.first.value = true;

    downloadingNotifier.value = downloadingNotifier.value.toList()..add(key);
  }

  static _downloadFinished(String key) {
    _downloadingState.remove(key);

    downloadingNotifier.value = downloadingNotifier.value.toList()..remove(key);
  }
}

extension DirectoryLengthExtension on Directory {
  Future<int> get length async {
    final files = listSync();
    final lengthList =
        await Future.wait(files.map((file) => File(file.path).length()));
    return lengthList.reduce((a, b) => a + b);
  }
}
