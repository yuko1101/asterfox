import 'package:asterfox/system/exceptions/asterfox_exception.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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
