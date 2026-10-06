import 'dart:io';

import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide MusicData;

import '../../utils/pair.dart';
import '../music_data/music_data.dart';
import '../music_data/youtube_music_data.dart';
import '../utils/youtube_music_utils.dart';
import 'audio_info.dart';

class AudioDownloader {
  static Future<AudioInfo> download(
    MusicData song, {
    String? customPath,
    ValueNotifier<Pair<int, int>>? bytesNotifier,
  }) async {
    if (song is YouTubeMusicData) {
      return await _downloadYouTubeAudio(
        song,
        null,
        customPath: customPath,
        bytesNotifier: bytesNotifier,
      );
    } else {
      throw UnimplementedError(
          "Downloading ${song.type} is not implemented yet.");
    }
  }

  static Future<AudioInfo> _downloadYouTubeAudio(
    YouTubeMusicData song,
    YoutubeExplode? yt, {
    String? customPath,
    ValueNotifier<Pair<int, int>>? bytesNotifier,
  }) async {
    final path = customPath ?? song.audioSavePath;
    final file = File(path);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);

    final ytContainer = YTContainer(yt);
    final streamInfo =
        (song.streamInfo == null || !await song.isAudioUrlAvailable())
            ? await song.refreshStreamInfo(ytContainer.get())
            : song.streamInfo!;

    final audioStream = ytContainer.get().videos.streamsClient.get(streamInfo);
    if (bytesNotifier != null) {
      bytesNotifier.value = Pair(0, streamInfo.size.totalBytes);
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
    ytContainer.close();

    return AudioInfo(extension: streamInfo.container.name);
  }
}
