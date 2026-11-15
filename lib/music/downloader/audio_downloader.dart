import 'dart:io';

import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide MusicData;

import '../../utils/pair.dart';
import '../music_data/music_data.dart';
import '../music_data/youtube_music_data.dart';
import 'audio_info.dart';

class AudioDownloader {
  /// Downloads the audio of [song] to [customPath], or to the song's own
  /// directory. [bytesNotifier] is given the downloaded and the total bytes.
  static Future<AudioInfo> download(
    MusicData song, {
    String? customPath,
    ValueNotifier<Pair<int, int>>? bytesNotifier,
  }) async {
    if (song is YouTubeMusicData) {
      return await _downloadYouTubeAudio(
        song,
        customPath: customPath,
        bytesNotifier: bytesNotifier,
      );
    } else {
      throw UnimplementedError(
          "Downloading ${song.type} is not implemented yet.");
    }
  }

  static Future<AudioInfo> _downloadYouTubeAudio(
    YouTubeMusicData song, {
    String? customPath,
    ValueNotifier<Pair<int, int>>? bytesNotifier,
  }) async {
    final file = File(customPath ?? song.audioSavePath);
    await file.parent.create(recursive: true);

    final yt = YoutubeExplode();
    try {
      final streamInfo =
          (song.streamInfo == null || !await song.isAudioUrlAvailable())
              ? await song.refreshStreamInfo(yt)
              : song.streamInfo!;

      final total = streamInfo.size.totalBytes;
      var received = 0;
      bytesNotifier?.value = Pair(0, total);

      // The file is written from its start, so that what an earlier, broken
      // download left behind is not kept in front of the audio.
      final sink = file.openWrite();
      try {
        await for (final data in yt.videos.streamsClient.get(streamInfo)) {
          sink.add(data);
          received += data.length;
          bytesNotifier?.value = Pair(received, total);
        }
      } finally {
        await sink.close();
      }

      return AudioInfo(extension: streamInfo.container.name);
    } finally {
      yt.close();
    }
  }
}
