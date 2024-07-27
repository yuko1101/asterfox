import 'dart:convert';
import 'dart:io';

class AudioInfo {
  AudioInfo({
    required this.extension,
  });

  final String extension;

  Map<String, dynamic> toJson() {
    return {
      "extension": extension,
    };
  }

  Future<void> save(String audioInfoPath) {
    final file = File(audioInfoPath);
    return file.writeAsString(jsonEncode(toJson()));
  }
}
