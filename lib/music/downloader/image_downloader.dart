import 'dart:io';

import 'package:http/http.dart' as http;

import '../music_data/music_data.dart';

class ImageDownloader {
  static Future<void> download(
    MusicData song, {
    String? customPath,
  }) async {
    final imageFile = File(customPath ?? song.imageSavePath);
    if (imageFile.existsSync()) {
      print("Image already saved");
      return;
    }
    final imageRes = await http.get(Uri.parse(song.remoteImageUrl));
    if (!imageFile.parent.existsSync()) {
      imageFile.parent.createSync(recursive: true);
    }
    imageFile.writeAsBytesSync(imageRes.bodyBytes);
  }
}
