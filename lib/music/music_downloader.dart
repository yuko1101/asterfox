import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:asterfox/main.dart';
import 'package:http/http.dart';
import 'package:flutter/foundation.dart';

import 'package:asterfox/config/local_musics_data.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/audio_source/youtube_audio.dart';
import 'package:flutter/cupertino.dart';

final ValueNotifier<List<String>> downloading = ValueNotifier<List<String>>([]);
final Map<String, ValueNotifier<int>> downloadProgress = {};

class MusicDownloader {
  static Future<void> download(AudioBase? song) async {
    if (song == null) return;
    if (song.isLocal) return;

    if (downloading.value.contains(song.key!)) return;

    downloading.value.add(song.key!);

    print("a");

    if (song is YouTubeAudio) {
      print("b");
      await _downloadFromYouTube(song);
    }

    await _saveImage(song);

    await LocalMusicsData.save(song);

    downloading.value.remove(song.key!);
  }

  static Future<void> _downloadFromYouTube(YouTubeAudio song) async {

    await _downloadMp3(song.url, song.copyAsLocal().url, song.key!);
  }



  static Future<String> _downloadMp3(String url, String downloadPath, String key) async {
    var completer = Completer<String>();

    downloadProgress[key] = ValueNotifier<int>(0);

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
        final percentage = (downloadedLength / contentLength! * 100).round();
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

  static Future<void> _saveImage(AudioBase song) async {
    final imageRes = await http.get(Uri.parse(song.imageUrl));
    final imageFile = File("$localPath/images/${getSongID(song)}.png");
    if (!imageFile.parent.existsSync()) imageFile.parent.createSync(recursive: true);
    imageFile.writeAsBytesSync(imageRes.bodyBytes);
    print("Download Complete!");
  }
}