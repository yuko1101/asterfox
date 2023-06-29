import 'package:flutter/foundation.dart';

class DataNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  DataNotifier(this._value);

  bool shouldNotify = false;

  @override
  T get value => _value;
  T _value;
  set value(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    shouldNotify = true;
  }

  void notify() {
    if (!shouldNotify) return;
    notifyListeners();
    shouldNotify = false;
  }
}
