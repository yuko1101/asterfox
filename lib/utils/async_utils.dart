import 'dart:async';

import 'package:flutter/foundation.dart';

import 'pair.dart';

/// `limit` - Maximum number of futures to be executed at the same time
class AsyncCore<T> {
  AsyncCore({
    this.limit,
  });
  final int? limit;

  final List<Future<T>> _running = [];
  final List<Pair<Future<T> Function(), Completer<T>>> _queue = [];

  Future<T> run(Future<T> Function() func) async {
    final completer = Completer<T>();
    if (limit == null || _running.length < limit!) {
      _execute(func, completer);
    } else {
      _queue.add(Pair(func, completer));
    }
    return completer.future;
  }

  Future<void> _execute(
      Future<T> Function() func, Completer<T> completer) async {
    final future = func();
    future.then((_) {
      if (_queue.isEmpty) return;
      final nextFunc = _queue.removeAt(0);
      _execute(nextFunc.first, nextFunc.second);
    });
    _running.add(future);
    completer.complete(await future);
  }
}

class ReadonlyValueNotifier<T> extends ChangeNotifier
    implements ValueListenable<T> {
  ReadonlyValueNotifier(
    this._notifier,
  ) {
    _updateValue();

    _notifier.addListener(_updateValue);
  }

  final ValueNotifier _notifier;
  late T _value;

  @override
  T get value => _value;

  void _updateValue() {
    _value = _notifier.value;
    notifyListeners();
  }
}

extension StreamToValueNotifier<T> on Stream<T> {
  ValueNotifier<T> toValueNotifier(T initialValue) {
    final valueNotifier = ValueNotifier<T>(initialValue);
    listen((event) {
      valueNotifier.value = event;
    }, onDone: () {
      valueNotifier.dispose();
    });

    return valueNotifier;
  }
}

extension ValueNotifierToReadonly<T> on ValueNotifier<T> {
  ReadonlyValueNotifier<T> toReadonly() {
    return ReadonlyValueNotifier(this);
  }
}
