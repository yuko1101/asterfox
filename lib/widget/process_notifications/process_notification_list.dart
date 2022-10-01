import 'package:asterfox/widget/process_notifications/animated_process_icon.dart';
import 'package:asterfox/widget/process_notifications/process_notification_widget.dart';
import 'package:asterfox/widget/process_notifications/process_notifications_button.dart';
import 'package:flutter/cupertino.dart';

class ProcessNotificationList {
  GlobalKey<ProcessNotificationsButtonState>? buttonKey;

  final ValueNotifier<List<ProcessNotificationData>> notificationsNotifier =
      ValueNotifier([]);

  Future<void> push(ProcessNotificationData notificationData) async {
    notificationsNotifier.value = [
      ...notificationsNotifier.value,
      notificationData
    ];
    if (notificationData.icon != null) {
      buttonKey?.currentState?.show(
        AnimatedProcessIcon(
          icon: notificationData.icon!,
        ),
      );
    }
    await notificationData.future;
    notificationsNotifier.value = [...notificationsNotifier.value]
      ..remove(notificationData);
  }

  void setButtonKey(GlobalKey<ProcessNotificationsButtonState>? key) {
    buttonKey = key;
  }
}
