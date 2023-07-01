import 'asterfox_exception.dart';

class SongAlreadyInstalledException extends AsterfoxException {
  SongAlreadyInstalledException()
      : super(title: "SongAlreadyInstalledException", description: "");
  @override
  String toString() => "SongAlreadyInstalledException";
}
