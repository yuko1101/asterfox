import 'asterfox_exception.dart';

class LocalSongNotFoundException extends AsterfoxException {
  LocalSongNotFoundException(this.audioId)
      : super(title: "LocalSongNotFoundException", description: audioId);
  final String audioId;
  @override
  String toString() => "LocalSongNotFoundException: $audioId";
}
