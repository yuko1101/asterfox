import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/pair.dart';
import '../music_data/music_data.dart';
import 'audio_info.dart';

class AudioDownloader {
  static Future<AudioInfo> download(
    MusicData song, {
    String? customPath,
    ValueNotifier<Pair<int, int>>? bytesNotifier,
  }) async {
    print("Starting audio download for ${song.title}: ${song.remoteAudioUrl}");
    final path = customPath ?? song.audioSavePath;
    final file = File(path);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);

    final url = await song.isAudioUrlAvailable()
        ? song.remoteAudioUrl
        : await song.refreshAudioUrl();

    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw Exception(
          "Failed to download audio. Status code: ${response.statusCode}");
    }

    final audioStream = response.stream;
    if (bytesNotifier != null) {
      bytesNotifier.value = Pair(0, response.contentLength!);
    }

    final fileStream = file.openWrite(mode: FileMode.writeOnlyAppend);

    await for (final data in audioStream) {
      fileStream.add(data);
      if (bytesNotifier != null) {
        final preValue = bytesNotifier.value;
        bytesNotifier.value =
            Pair(preValue.first + data.length, preValue.second);
      }
    }
    await fileStream.close();
    client.close();

    // TODO: get the extension from audioInfo
    return AudioInfo(extension: "m4a");
  }
}
