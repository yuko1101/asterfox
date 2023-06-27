import 'package:asterfox/system/exceptions/asterfox_exception.dart';

class SongAlreadyInstallingException extends AsterfoxException {
  SongAlreadyInstallingException()
      : super(title: "SongAlreadyInstallingException", description: "");
  @override
  String toString() => "SongAlreadyInstallingException";
}
