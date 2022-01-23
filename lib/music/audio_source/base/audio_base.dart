import 'package:uuid/uuid.dart';

class AudioBase {
  AudioBase({
    required this.url,
    required this.title,
    required this.description,
    required this.author,
    required this.isLocal,
    this.key

  });
  final String url;
  final String title;
  final String description;
  final String author;
  bool isLocal;
  String? key;

  String getKey() {
    key ??= const Uuid().v4();
    return key!;
  }
}