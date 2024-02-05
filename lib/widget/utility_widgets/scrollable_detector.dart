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

  @override
  void initState() {
    _controller = widget.controller;

    _isScrollable = false;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isScrollable = _controller.position.maxScrollExtent > 0;
      });
    });
    return widget.builder(context, _isScrollable);
  }
}
