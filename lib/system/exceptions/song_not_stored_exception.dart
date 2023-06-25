import 'package:asterfox/system/exceptions/asterfox_exception.dart';

class SongNotStoredException extends AsterfoxException {
  SongNotStoredException()
      : super(title: "SongNotStoredException", description: "");
  @override
  String toString() => "SongNotStoredException";
}
