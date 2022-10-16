import 'dart:math';

import 'package:asterfox/widget/process_notifications/process_notification_list.dart';
import 'package:flutter/material.dart';

class ProcessNotificationsButton extends StatefulWidget {
  const ProcessNotificationsButton({
    required this.notificationList,
    Key? key,
  }) : super(key: key);
  final ProcessNotificationList notificationList;

  static Duration notificationBadgeAddDelay =
      const Duration(milliseconds: 1000);

  @override
  State<ProcessNotificationsButton> createState() =>
      ProcessNotificationsButtonState();
}

class ProcessNotificationsButtonState extends State<ProcessNotificationsButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _runningController;
  final ValueNotifier<Widget?> _widgetToShowNotifier = ValueNotifier(null);
  final ValueNotifier<int> _processCountNotifier = ValueNotifier(0);

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

    int preCount = widget.notificationList.notificationsNotifier.value.length;
    _processCountNotifier.value = preCount;
    widget.notificationList.notificationsNotifier.addListener(() async {
      final diff =
          widget.notificationList.notificationsNotifier.value.length - preCount;
      preCount = widget.notificationList.notificationsNotifier.value.length;
      if (diff > 0) {
        await Future.delayed(
            ProcessNotificationsButton.notificationBadgeAddDelay);
      }
      _processCountNotifier.value = _processCountNotifier.value + diff;
    });
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
            valueListenable: _widgetToShowNotifier,
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
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).backgroundColor),
                          clipBehavior: Clip.antiAlias,
                          child: AnimatedBuilder(
                            animation: _runningController,
                            builder: (context, child) => Transform.rotate(
                              angle: _runningController.value * 2 * pi,
                              child: IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: () {
                                  // TODO: open process list
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Notification Count Badge
                      Positioned(
                        right: 0,
                        top: 0,
                        child: ValueListenableBuilder(
                          valueListenable: _processCountNotifier,
                          builder: (_, count, __) => Visibility(
                            visible: count != 0,
                            child: Container(
                              height: 20,
                              width: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                              child: FittedBox(
                                child: Text("$count",
                                    style:
                                        const TextStyle(color: Colors.white)),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widgetToShow != null) ...[
                  const SizedBox(
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
    _widgetToShowNotifier.value = widget;
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    await _controller.reverse();
    if (_widgetToShowNotifier.value == widget) {
      _widgetToShowNotifier.value = null;
    }
  }
}
