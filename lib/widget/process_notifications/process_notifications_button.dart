import 'dart:math';

import 'package:asterfox/screens/home_screen.dart';
import 'package:asterfox/widget/process_notifications/process_notification_widget.dart';
import 'package:flutter/material.dart';

class ProcessNotificationsButton extends StatefulWidget {
  const ProcessNotificationsButton({Key? key}) : super(key: key);

  @override
  State<ProcessNotificationsButton> createState() =>
      ProcessNotificationsButtonState();
}

class ProcessNotificationsButtonState extends State<ProcessNotificationsButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _runningController;
  final ValueNotifier<Widget?> widgetToShowNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _runningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _runningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: pow(_controller.value, 2) * 40 + 60,
          height: 60,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            color: Colors.orange,
          ),
          child: ValueListenableBuilder<Widget?>(
            valueListenable: widgetToShowNotifier,
            builder: (context, widgetToShow, child) => ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              reverse: true,
              clipBehavior: Clip.antiAlias,
              children: [
                Container(
                  height: 60,
                  width: 60,
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).backgroundColor),
                    child: AnimatedBuilder(
                      animation: _runningController,
                      builder: (context, child) => Transform.rotate(
                        angle: _runningController.value * 2 * pi,
                        child: IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            HomeScreen.processNotificationList.push(
                              ProcessNotificationData(
                                  title: const Text("a"),
                                  icon: const Icon(Icons.download),
                                  future: Future.delayed(
                                      const Duration(milliseconds: 10000))),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                if (widgetToShow != null) ...[
                  SizedBox(
                    width: 5,
                  ),
                  Opacity(
                    opacity: pow(max(_controller.value - 0.5, 0) * 2, 2.0)
                        .toDouble(),
                    child: widgetToShow,
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> show(Widget widget) async {
    widgetToShowNotifier.value = widget;
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    await _controller.reverse();
    if (widgetToShowNotifier.value == widget) widgetToShowNotifier.value = null;
  }
}
