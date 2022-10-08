import 'package:flutter/cupertino.dart';

class AnimatedProcessIcon extends StatefulWidget {
  const AnimatedProcessIcon({
    required this.icon,
    Key? key,
  }) : super(key: key);
  final Widget icon;

  @override
  State<AnimatedProcessIcon> createState() => _AnimatedProcessIconState();
}

class _AnimatedProcessIconState extends State<AnimatedProcessIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        margin: EdgeInsets.only(bottom: (1 - _controller.value) * 100),
        child: FadeTransition(
          opacity: _controller,
          child: widget.icon,
        ),
      ),
    );
  }
}
