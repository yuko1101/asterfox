import 'dart:async';

import 'package:easy_app/utils/pair.dart';

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
