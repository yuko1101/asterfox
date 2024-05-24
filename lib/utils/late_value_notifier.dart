import 'package:flutter/foundation.dart';

class LateValueNotifier<T> extends ValueNotifier<T?> {
  LateValueNotifier() : super(null);

  @override
  T get value => super.value!;
  @override
  set value(T? newValue) {
    assert(newValue != null);
    super.value = newValue;
  }

  bool get isInitialized => super.value != null;
}
