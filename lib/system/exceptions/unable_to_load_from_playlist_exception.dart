import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'asterfox_exception.dart';

class UnableToLoadFromPlaylistException extends AsterfoxException {
  UnableToLoadFromPlaylistException({
    required this.video,
    required this.cause,
  }) : super(title: "UnableToLoadFromPlaylistException", description: "");

  final Video video;
  final Object cause;

  @override
  String toString() => "UnableToLoadFromPlaylistException";
}
