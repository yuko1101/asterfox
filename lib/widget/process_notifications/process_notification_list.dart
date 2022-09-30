import 'package:asterfox/widget/process_notifications/animated_process_icon.dart';
import 'package:asterfox/widget/process_notifications/process_notification_widget.dart';
import 'package:asterfox/widget/process_notifications/process_notifications_button.dart';
import 'package:flutter/cupertino.dart';

class ProcessNotificationList {
  ProcessNotificationList({
    this.buttonKey,
  });
  GlobalKey<ProcessNotificationsButtonState>? buttonKey;

  final List<ProcessNotificationData> notificationList = [];

  Future<void> push(ProcessNotificationData notificationData) async {
    notificationList.add(notificationData);
    if (notificationData.icon != null) {
      buttonKey?.currentState?.show(
        AnimatedProcessIcon(
          icon: notificationData.icon!,
        ),
      );
    }
    await notificationData.future;
  }

  void setButtonKey(GlobalKey<ProcessNotificationsButtonState>? key) {
    buttonKey = key;
  }
}
