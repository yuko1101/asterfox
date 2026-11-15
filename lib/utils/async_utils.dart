import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs futures with at most [limit] of them at the same time (no limit when
/// null). A future that fails frees its slot like one that succeeds.
class AsyncCore<T> {
  AsyncCore({
    this.limit,
  });
  final int? limit;

  int _running = 0;
  final List<Completer<void>> _waiting = [];

  Future<T> run(Future<T> Function() func) async {
    if (limit != null && _running >= limit!) {
      // The slot is handed over by the run that frees it, still counted.
      final slot = Completer<void>();
      _waiting.add(slot);
      await slot.future;
    } else {
      _running++;
    }
    try {
      return await func();
    } finally {
      if (_waiting.isNotEmpty) {
        _waiting.removeAt(0).complete();
      } else {
        _running--;
      }
    }
  }
}

/// A read-only view of a [ValueNotifier]. Listeners are added to the notifier
/// itself, so the view holds nothing of its own and needs no disposing.
class ReadonlyValueNotifier<T> implements ValueListenable<T> {
  ReadonlyValueNotifier(this._notifier);

  final ValueNotifier<T> _notifier;

  @override
  T get value => _notifier.value;

  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _notifier.removeListener(listener);
}

extension ValueNotifierToReadonly<T> on ValueNotifier<T> {
  ReadonlyValueNotifier<T> toReadonly() => ReadonlyValueNotifier(this);
}
