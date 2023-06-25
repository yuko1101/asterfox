import 'package:asterfox/system/exceptions/asterfox_exception.dart';

class NetworkException extends AsterfoxException {
  NetworkException() : super(title: "NetworkException", description: "");
  @override
  String toString() => "NetworkException";
}
