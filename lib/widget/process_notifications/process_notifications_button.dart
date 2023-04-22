import 'dart:math';

import 'package:asterfox/widget/asterfox_dialog.dart';
import 'package:asterfox/widget/process_notifications/process_notification_list.dart';
import 'package:asterfox/widget/process_notifications/process_notification_screen.dart';
import 'package:asterfox/widget/process_notifications/process_notification_widget.dart';
import 'package:easy_app/easy_app.dart';
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
  late VoidCallback _spinIfProcessNotEmpty;
  bool _disposed = false;

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

    // update process counter badge
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

    // spin gear icon while running
    _runningController.animateTo(_runningController.value + 1 / 6);
    _runningController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          widget.notificationList.notificationsNotifier.value.isNotEmpty) {
        double animateTo = _runningController.value + 1 / 6;
        if (animateTo > 1) {
          animateTo = animateTo - 1;
          _runningController.reset();
        }
        _runningController.animateTo(animateTo);
      }
    });
    _spinIfProcessNotEmpty = () {
      if (_runningController.status == AnimationStatus.completed &&
          widget.notificationList.notificationsNotifier.value.isNotEmpty) {
        double animateTo = _runningController.value + 1 / 6;
        if (animateTo > 1) {
          animateTo = animateTo - 1;
          _runningController.reset();
        }
        _runningController.animateTo(animateTo);
      }
    };
    widget.notificationList.notificationsNotifier
        .addListener(_spinIfProcessNotEmpty);
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    _runningController.dispose();
    widget.notificationList.notificationsNotifier
        .removeListener(_spinIfProcessNotEmpty);
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
                                  EasyApp.pushPage(
                                    context,
                                    ProcessNotificationScreen(
                                      widget.notificationList,
                                    ),
                                  );
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
    if (_disposed) return;
    _widgetToShowNotifier.value = widget;
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    await _controller.reverse();
    if (_widgetToShowNotifier.value == widget) {
      _widgetToShowNotifier.value = null;
    }
  }
}

class ProcessDialog extends StatelessWidget {
  const ProcessDialog(this.processNotificationList, {super.key});
  final ProcessNotificationList processNotificationList;

  @override
  Widget build(BuildContext context) {
    return AsterfoxDialog(
      child: Flexible(
        child: ValueListenableBuilder<List<ProcessNotificationData>>(
          valueListenable: processNotificationList.notificationsNotifier,
          builder: (context, value, child) => ListView.builder(
            itemBuilder: (context, index) =>
                ProcessNotificationWidget(notificationData: value[index]),
            itemCount: value.length,
          ),
        ),
      ),
    );
  }
}
