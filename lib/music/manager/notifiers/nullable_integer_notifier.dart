import 'package:flutter/foundation.dart';

class NullableIntegerNotifier extends ChangeNotifier implements ValueListenable<int?> {
  NullableIntegerNotifier(this.value);
  @override
  int? value;

  void notify() {
    notifyListeners();
  }
}