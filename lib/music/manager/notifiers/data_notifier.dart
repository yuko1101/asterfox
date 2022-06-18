import 'package:flutter/foundation.dart';

class DataNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  DataNotifier(this.value);
  @override
  T value;

  void notify() {
    notifyListeners();
  }
}
