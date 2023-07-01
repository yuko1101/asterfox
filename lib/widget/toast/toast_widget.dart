import 'dart:async';

import 'package:easy_app/utils/pair.dart';
import 'package:flutter/material.dart';

import '../../utils/math.dart';

class Toast extends StatefulWidget {
  const Toast({Key? key}) : super(key: key);

  static final List<Pair<ToastData, Completer>> _queue = [];
  static final ValueNotifier<ToastData?> _toastMessageNotifier =
      ValueNotifier(null);

  /// Future ends when the toast begins to disappear.
  static Future<void> showToast(ToastData toastData) async {
    if (_toastMessageNotifier.value != null) {
      final completer = Completer();
      _queue.add(Pair(toastData, completer));
      await completer.future;
    } else {
      await showForcedToast(toastData);
    }
  }

  static Future<void> showForcedToast(ToastData toastData,
      [Completer? completer]) async {
    _toastMessageNotifier.value = toastData;
    if (toastData.duration != null) {
      await Future.delayed(toastData.duration!);
    } else {
      await toastData.wait;
    }

    completer?.complete();

    // show next toast from queue
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      showForcedToast(next.first, next.second);
    } else {
      _toastMessageNotifier.value = null;
    }
  }

  @override
  State<Toast> createState() => _ToastState();
}

class _ToastState extends State<Toast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  // 0 => 1 トースト表示
  // 1 => 0 トースト非表示
  static final Tween<double> _tween = Tween<double>(begin: 0, end: 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progress = _controller.drive(_tween);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ToastData? _lastToast;
  ToastData? _currentToast;
  @override
  Widget build(BuildContext context) {
    bool isReversing = true;
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) => ValueListenableBuilder<ToastData?>(
          valueListenable: Toast._toastMessageNotifier,
          builder: (_, value, __) {
            if (value != _currentToast) {
              _lastToast = _currentToast;
              isReversing = true;
              _controller.reverse().then((_) {
                if (value == null) return;
                isReversing = false;
                _controller.forward();
              });
              _currentToast = value;
            }

            final oldWidget =
                _lastToast != null ? _lastToast!.message : Container();
            final newWidget =
                _currentToast != null ? _currentToast!.message : Container();

            return Positioned(
              bottom: MathUtils.log(_progress.value * 2, 2) * 120 - 60,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: isReversing ? oldWidget : newWidget,
                ),
              ),
            );
          }),
    );
  }
}

class ToastData {
  ToastData({
    required this.message,
    this.duration,
    this.wait,
  }) {
    assert(duration != null || wait != null);
  }
  final Widget message;
  final Duration? duration;
  final Future? wait;
}
