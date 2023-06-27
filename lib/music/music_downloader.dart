import 'dart:async';
import 'dart:io';

import 'package:asterfox/system/exceptions/song_already_installed_exception.dart';
import 'package:asterfox/system/exceptions/song_already_installing_exception.dart';
import 'package:asterfox/system/firebase/cloud_firestore.dart';
import 'package:asterfox/utils/async_utils.dart';
import 'package:easy_app/utils/pair.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../data/local_musics_data.dart';
import '../system/exceptions/network_exception.dart';
import '../utils/network_check.dart';
import 'audio_source/music_data.dart';
import 'audio_source/youtube_music_data.dart';

class DownloadManager {
  static final Map<String, Pair<ValueNotifier<bool>, ValueNotifier<int>>>
      _downloadingState = {};

  static final ValueNotifier<List<String>> downloadingNotifier =
      ValueNotifier([]);

  /// If `customPath` provided, this method doesn't download the thumbnail of the song.
  static Future<void> download(
    MusicData song, {
    File? customPath,
    String? customDownloadKey,
  }) async {
    final String downloadKey = customDownloadKey ?? song.audioId;

    if (song.isInstalled) {
      throw SongAlreadyInstalledException();
    }
    if (isDownloading(downloadKey)) {
      throw SongAlreadyInstallingException();
    }

    NetworkCheck.check();

    _downloadStarted(downloadKey);
    final notifiers = _getNotifiers(downloadKey);

    if (!(await song.isAudioUrlAvailable())) await song.refreshAudioUrl();

    // download
    await for (final progress
        in _MusicDownloader.download(song, customPath: customPath)) {
      notifiers.second.value = progress;
    }

    // save file size
    song.size =
        await Directory(customPath?.parent.path ?? song.directoryPath).length;
    // if the song has already stored, update file size property and save.
    if (song.isStored) {
      await LocalMusicsData.musicData
          .get([song.audioId])
          .set(key: "size", value: song.size)
          .save(compact: LocalMusicsData.compact);
      await CloudFirestoreManager.addOrUpdateSongs([song]);
    }

    _downloadFinished(downloadKey);
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

class _MusicDownloader {
  /// Throws [NetworkException] if network is not accessible.
  /// Throws [VideoUnplayableException]
  static Stream<int> download(MusicData song, {File? customPath}) async* {
    yield* downloadMp3(song, customPath?.path ?? song.audioSavePath);

    if (customPath == null) {
      await _saveImage(song);
      // インストールが完了してることが判断できるように空のテキストファイルを生成する
      File(song.installCompleteFilePath).createSync();
    }

    print("finished!");
  }

  /// Throws [VideoUnplayableException]
  static Stream<int> downloadMp3(MusicData song, String downloadPath) async* {
    if (song is YouTubeMusicData) {
      yield* _downloadFromYouTube(song.id, downloadPath);
    } else {
      yield* _downloadMp3(await song.getAvailableAudioUrl(), downloadPath);
    }
  }

  /// Throws [VideoUnplayableException]
  static Stream<int> _downloadFromYouTube(
      String id, String downloadPath) async* {
    final File file = File(downloadPath);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);

    final YoutubeExplode yt = YoutubeExplode();
    final manifest = await yt.videos.streamsClient.getManifest(id);
    final streams =
        manifest.audioOnly.isEmpty ? manifest.audio : manifest.audioOnly;
    final audio = streams.first;
    final audioStream = yt.videos.streamsClient.get(audio);
    final output = file.openWrite(mode: FileMode.writeOnlyAppend);

    final len = audio.size.totalBytes;
    var count = 0;

    final msg = "Downloading $id from youtube";
    stdout.writeln(msg);

    int preProgress = 0;
    await for (final data in audioStream) {
      count += data.length;
      output.add(data);
      final progress = ((count / len) * 100).ceil();
      if (progress != preProgress) {
        yield progress;
        preProgress = progress;
      }
    }
    await output.close();

    yt.close();
  }

  // TODO: add startsAt and endsAt as parameters to download a part of the song
  static Stream<int> _downloadMp3(String url, String downloadPath) async* {
    final request = Request('GET', Uri.parse(url));
    final StreamedResponse response = await Client().send(request);

    final contentLength = response.contentLength;

    List<int> bytes = [];

    final File file = File(downloadPath);

    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);

    print("downloading...");

    int preProgress = 0;
    try {
      await for (final newBytes in response.stream) {
        bytes.addAll(newBytes);
        final downloadedLength = bytes.length;
        final progress = (downloadedLength / contentLength! * 100).ceil();
        if (progress != preProgress) {
          yield progress;
          preProgress = progress;
          print(progress);
        }
      }
    } catch (e) {
      rethrow;
    }
    await file.writeAsBytes(bytes);
    print("completed!");
  }

  static Future<void> _saveImage(MusicData song) async {
    final imageFile = File(song.imageSavePath);
    if (imageFile.existsSync()) {
      print("Image already saved");
      return;
    }
    final imageRes = await http.get(Uri.parse(song.remoteImageUrl));
    if (!imageFile.parent.existsSync()) {
      imageFile.parent.createSync(recursive: true);
    }
    imageFile.writeAsBytesSync(imageRes.bodyBytes);
    print("Download Complete!");
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
