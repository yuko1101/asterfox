import 'package:asterfox/system/exceptions/asterfox_exception.dart';

class NotLoggedInException extends AsterfoxException {
  NotLoggedInException()
      : super(title: "NotLoggedInException", description: "");
  @override
  String toString() => "NotLoggedInException";
}
