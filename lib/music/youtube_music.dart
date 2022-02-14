import 'dart:io';

import 'package:asterfox/music/audio_source/youtube_audio.dart';
import 'package:asterfox/util/config_file.dart';
import 'package:asterfox/util/logger.dart';
import 'package:asterfox/util/network_util.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../main.dart';

Future<String?> getAudioURL(String videoId) async {
  // 曲が保存されているかどうか
  bool local = await isLocal(videoId);
  if (local) {
    ConfigFile config = await ConfigFile(await getFile(videoId), {}).load();
    return config.get([videoId]).getValue("url") as String;
  } else {
    // オンライン上から取得

    // インターネット接続確認
    if (!await networkAccessible()) {
      await showNetworkAccessDeniedMessage();
      return null;
    }

    final YoutubeExplode yt = YoutubeExplode();
    StreamManifest manifest;
    try {
      manifest = await yt.videos.streamsClient.getManifest(videoId);
    } on VideoUnplayableException {
      Fluttertoast.showToast(msg: "この曲は再生できません");
      yt.close();
      return null;
    }

    // if (manifest.audio.isEmpty && manifest.audioOnly.isEmpty) {
    //   Fluttertoast.showToast(msg: "この曲の音声データが見つかりませんでした");
    //   return null;
    // }

    yt.close();

    return manifest.audioOnly.withHighestBitrate().url.toString();

  }
}

Future<YouTubeAudio?> getYouTubeAudio(String videoId) async {
  // 曲が保存されているかどうか
  bool local = await isLocal(videoId);
  if (local) {
    ConfigFile config = await ConfigFile(await getFile(videoId), {}).load();
    return YouTubeAudio.fromJson(config.getValue(videoId) as Map<String, dynamic>, local: true);
  } else {
    // オンライン上から取得

    // インターネット接続確認
    if (!await networkAccessibleSync()) {
      await showNetworkAccessDeniedMessage();
      return null;
    }

    final YoutubeExplode yt = YoutubeExplode();
    StreamManifest manifest;
    try {
      manifest = await yt.videos.streamsClient.getManifest(videoId);
    } on VideoUnplayableException {
      Fluttertoast.showToast(msg: "この曲は再生できません");
      yt.close();
      return null;
    }

    // if (manifest.audio.isEmpty && manifest.audioOnly.isEmpty) {
    //   Fluttertoast.showToast(msg: "この曲の音声データが見つかりませんでした");
    //   return null;
    // }

    final Video video = await yt.videos.get(videoId);


    yt.close();

    return YouTubeAudio(
        url: manifest.audioOnly.withHighestBitrate().url.toString(),
        id: videoId,
        title: video.title,
        description: video.description,
        author: video.author,
        authorId: video.channelId.value,
        duration: video.duration?.inMilliseconds ?? 0,
        isLocal: false);

  }
}



Future<String> getFilePath(String id) async {
  final path = localPath;
  return '$path/music/yt-$id.mp3';
}

Future<File> getFile(String id) async {
  return File(await getFilePath(id));
}

Future<bool> isLocal(String id) async {
  if (localPath == null) return false;
  try {
    final file = await getFile(id);
    log("file: " + file.existsSync().toString());
    return file.existsSync();
  } catch (e) {
    log("error: false");
    log(e);
    return false;
  }
}
