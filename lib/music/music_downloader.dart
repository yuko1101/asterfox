import 'dart:async';
import 'dart:io';

import 'package:asterfox/system/firebase/cloud_firestore.dart';
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

final ValueNotifier<List<String>> downloading = ValueNotifier<List<String>>([]);
final Map<String, ValueNotifier<int>> downloadProgress = {};

class MusicDownloader {
  /// Throws [NetworkException] if network is not accessible.
  /// Throws [VideoUnplayableException]
  static Future<void> download(MusicData song) async {
    if (song.isInstalled) return;

    NetworkCheck.check();

    if (downloading.value.contains(song.key)) return;

    downloadProgress[song.key] ??= ValueNotifier<int>(0);
    downloading.value = [...downloading.value, song.key];

    await downloadMp3(song, song.audioSavePath, song.key, false);

    await _saveImage(song);

    // save file size
    song.size = await Directory(song.directoryPath).length;
    // if the song has already stored, update file size property and save.
    if (song.isStored) {
      await LocalMusicsData.musicData
          .get([song.audioId])
          .set(key: "size", value: song.size)
          .save(compact: LocalMusicsData.compact);
      await CloudFirestoreManager.addOrUpdateSongs([song]);
    }

    // インストールが完了してることが判断できるように空のテキストファイルを生成する
    File(song.installCompleteFilePath).createSync();

    print("finished!");

    downloadProgress.remove(song.key);
    final List<String> preDownloading = [...downloading.value]; // immutable
    preDownloading.remove(song.key);
    downloading.value = preDownloading;
  }

  /// Throws [VideoUnplayableException]
  static Future<void> downloadMp3(
      MusicData song, String downloadPath, String key,
      [bool manageDownload = true]) async {
    if (manageDownload) {
      if (downloading.value.contains(song.key)) return;
      downloadProgress[key] ??= ValueNotifier<int>(0);
      downloading.value = [...downloading.value, key];
    }

    if (song is YouTubeMusicData) {
      await _downloadFromYouTube(song.id, downloadPath, key);
    } else {
      await _downloadMp3(await song.getAvailableAudioUrl(), downloadPath, key);
    }

    if (manageDownload) {
      downloadProgress.remove(song.key);
      final List<String> preDownloading = [...downloading.value]; // immutable
      preDownloading.remove(song.key);
      downloading.value = preDownloading;
    }
  }

  /// Throws [VideoUnplayableException]
  static Future<void> _downloadFromYouTube(
      String id, String downloadPath, String key) async {
    final File file = File(downloadPath);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);

    final YoutubeExplode yt = YoutubeExplode();
    final manifest = await yt.videos.streamsClient.getManifest(id);
    final streams =
        manifest.audioOnly.isEmpty ? manifest.audio : manifest.audioOnly;
    final audio = streams.first;
    final audioStream = yt.videos.streamsClient.get(audio);
    final output = file.openWrite(mode: FileMode.writeOnlyAppend);

    var len = audio.size.totalBytes;
    var count = 0;

    var msg = "Downloading $id from youtube";
    stdout.writeln(msg);
    await for (final data in audioStream) {
      count += data.length;
      var progress = ((count / len) * 100).ceil();
      downloadProgress[key]!.value = progress;
      output.add(data);
    }
    await output.close();

    yt.close();
  }

  // TODO: add startsAt and endsAt as parameters to download a part of the song
  static Future<String> _downloadMp3(
      String url, String downloadPath, String key) async {
    var completer = Completer<String>();

    final request = Request('GET', Uri.parse(url));
    final StreamedResponse response = await Client().send(request);

    final contentLength = response.contentLength;

    List<int> bytes = [];

    final File file = File(downloadPath);

    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);

    print("downloading...");

    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        final downloadedLength = bytes.length;
        final percentage = (downloadedLength / contentLength! * 100).ceil();
        downloadProgress[key]!.value = percentage;
        print(percentage);
      },
      onDone: () async {
        await file.writeAsBytes(bytes);
        completer.complete("done");
        print("completed!");
      },
      onError: (e) {
        completer.complete("error");
        print(e);
      },
      cancelOnError: true,
    );

    return completer.future;
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
