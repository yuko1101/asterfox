import 'dart:io';

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
      return null;
    }

    // if (manifest.audio.isEmpty && manifest.audioOnly.isEmpty) {
    //   Fluttertoast.showToast(msg: "この曲の音声データが見つかりませんでした");
    //   return null;
    // }

    return manifest.audioOnly.withHighestBitrate().url.toString();

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
