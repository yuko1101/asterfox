import 'package:asterfox/system/exceptions/asterfox_exception.dart';

class InvalidTypeOfMediaUrlException extends AsterfoxException {
  InvalidTypeOfMediaUrlException(this.mediaUrl)
      : super(title: "InvalidTypeOfMediaUrlException", description: mediaUrl);
  final String mediaUrl;
  @override
  String toString() => "InvalidTypeOfMediaUrlException: $mediaUrl";
}
