import 'package:flutter/material.dart';

class Toast extends StatefulWidget {
  const Toast({Key? key}) : super(key: key);

  static final ValueNotifier<ToastData?> toastMessageNotifier =
      ValueNotifier(null);

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
          valueListenable: Toast.toastMessageNotifier,
          builder: (_, value, __) {
            print(_progress.value);
            if (value != _currentToast) {
              _lastToast = _currentToast;
              isReversing = true;
              _controller.reverse().then((_) {
                isReversing = false;
                _controller.forward();
              });
              _currentToast = value;
            }

            final oldWidget = _lastToast != null
                ? ToastMessageWidget(_lastToast!)
                : Container();
            final newWidget = _currentToast != null
                ? ToastMessageWidget(_currentToast!)
                : Container();

            return Positioned(
              bottom: _progress.value * 120 - 60,
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

class ToastMessageWidget extends StatelessWidget {
  const ToastMessageWidget(this.toast, {Key? key}) : super(key: key);
  final ToastData toast;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: toast.message,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).backgroundColor,
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
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
