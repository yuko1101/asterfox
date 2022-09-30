import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProcessNotificationData<T> {
  ProcessNotificationData({
    required this.title,
    this.description,
    this.icon,
    required this.future,
    this.progressListenable,
  });
  final Widget title;
  final Widget? description;
  final Widget? icon;
  final Future future;
  final ValueListenable<T>? progressListenable;
}

class ProcessNotificationWidget extends StatelessWidget {
  const ProcessNotificationWidget({
    required this.notificationData,
    Key? key,
  }) : super(key: key);
  final ProcessNotificationData notificationData;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: notificationData.title,
    );
  }
}
