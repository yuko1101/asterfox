import 'package:flutter/material.dart';

class ScrollableDetector extends StatefulWidget {
  const ScrollableDetector({
    required this.controller,
    required this.builder,
    super.key,
  });

  final ScrollController controller;
  final Widget Function(BuildContext context, bool isScrollable) builder;

  @override
  State<ScrollableDetector> createState() => _ScrollableDetectorState();
}

class _ScrollableDetectorState extends State<ScrollableDetector> {
  late final ScrollController _controller;
  late bool _isScrollable;

  bool _cancelNextCheck = false;

  @override
  void initState() {
    _controller = widget.controller;

    _isScrollable = false;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // スクロール可能であるかチェックするためにまずレンダリングして、
    // 次のフレームで最大スクロールをチェックしてそれに合わせて再レンダリングする。
    // (2回目ではチェックをキャンセルしてループを防ぐ)
    if (!_cancelNextCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isScrollable = _controller.position.maxScrollExtent > 0;
          _cancelNextCheck = true;
        });
      });
    } else {
      _cancelNextCheck = false;
    }
    return widget.builder(context, _isScrollable);
  }
}
