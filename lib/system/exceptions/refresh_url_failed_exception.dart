import 'asterfox_exception.dart';

class RefreshUrlFailedException extends AsterfoxException {
  RefreshUrlFailedException()
      : super(title: "RefreshUrlFailedException", description: "");
  @override
  String toString() => "RefreshUrlFailedException";
}
