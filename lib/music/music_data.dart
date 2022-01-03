import 'music_detail.dart';
import 'package:uuid/uuid.dart';

class MusicData {
  MusicData({
    required this.url,
    required this.detail,
  });
  final String url;
  final MusicDetail detail;

  final String uuid = const Uuid().v4();

}