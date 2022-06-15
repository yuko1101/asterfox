import 'dart:async';
import 'dart:io';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/audio_source/youtube_music_data.dart';
import 'package:asterfox/utils/extensions.dart';
import 'package:easy_app/easy_app.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:asterfox/main.dart';
import 'package:http/http.dart';
import 'package:flutter/foundation.dart';
import 'package:asterfox/data/local_musics_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final ValueNotifier<List<String>> downloading = ValueNotifier<List<String>>([]);
final Map<String, ValueNotifier<int>> downloadProgress = {};

class MusicDownloader {
  static Future<void> download(MusicData? song, {bool saveToJSON = true}) async {
    if (song == null) return;
    if (song.isLocal) return;

    if (downloading.value.contains(song.key)) return;

    downloadProgress[song.key] ??= ValueNotifier<int>(0);
    downloading.value = [...downloading.value, song.key];

    if (song is YouTubeMusicData) {
      await _downloadFromYouTube(song);
    } else {
      await _downloadMp3(song.url, song.savePath, song.key);
    }
    song.url = song.savePath;

    await _saveImage(song, song.imageSavePath);

    song.imageUrl = song.imageSavePath;

    if (saveToJSON) await LocalMusicsData.save(song);

    print("finished!");

    downloadProgress.remove(song.key);
    final List<String> preDownloading = [...downloading.value]; // immutable
    preDownloading.remove(song.key);
    downloading.value = preDownloading;
  }

  static Future<void> _downloadFromYouTube(YouTubeMusicData song) async {
    final String id = song.id;
    final String downloadPath = song.savePath;
    final String key = song.key;

    final File file = File(downloadPath);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);

    final YoutubeExplode yt = YoutubeExplode();
    final manifest = await yt.videos.streamsClient.getManifest(id);
    final streams = manifest.audioOnly.isEmpty ? manifest.audio : manifest.audioOnly;
    final audio = streams.first;
    final audioStream = yt.videos.streamsClient.get(audio);
    final output = file.openWrite(mode: FileMode.writeOnlyAppend);

    var len = audio.size.totalBytes;
    var count = 0;

    var msg = "Downloading ${song.title}";
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
  static Future<String> _downloadMp3(String url, String downloadPath, String key) async {
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

  static Future<void> _saveImage(MusicData song, String path) async {
    if (!song.imageUrl.isUrl) {
      print("Image already saved");
      return;
    }
    final imageRes = await http.get(Uri.parse(song.imageUrl));
    final imageFile = File(path);
    if (!imageFile.parent.existsSync()) imageFile.parent.createSync(recursive: true);
    imageFile.writeAsBytesSync(imageRes.bodyBytes);
    print("Download Complete!");
  }
}