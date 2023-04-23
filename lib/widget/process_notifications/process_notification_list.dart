import 'package:asterfox/widget/process_notifications/animated_process_icon.dart';
import 'package:asterfox/widget/process_notifications/process_notification_widget.dart';
import 'package:asterfox/widget/process_notifications/process_notifications_button.dart';
import 'package:flutter/cupertino.dart';

class ProcessNotificationList {
  GlobalKey<ProcessNotificationsButtonState>? buttonKey;

  final ValueNotifier<List<ProcessNotificationData>> notificationsNotifier =
      ValueNotifier([]);

  final ValueNotifier<List<ProcessNotificationData>> erroredProcessList =
      ValueNotifier([]);

  Future<void> push(ProcessNotificationData notificationData) async {
    notificationsNotifier.value = [
      ...notificationsNotifier.value,
      notificationData
    ];

    final int startTime = DateTime.now().millisecondsSinceEpoch;

    if (notificationData.icon != null) {
      buttonKey?.currentState?.show(
        AnimatedProcessIcon(
          icon: notificationData.icon!,
        ),
      );
    }
    await notificationData.future;

    () async {
      final int endTime = DateTime.now().millisecondsSinceEpoch;
      if (endTime - startTime <
          ProcessNotificationsButton.notificationBadgeAddDelay.inMilliseconds) {
        final Duration toWait =
            ProcessNotificationsButton.notificationBadgeAddDelay -
                Duration(milliseconds: endTime - startTime);
        await Future.delayed(toWait);
      }
      notificationsNotifier.value = [...notificationsNotifier.value]
        ..remove(notificationData);

      if (notificationData.errorListNotifier != null &&
          notificationData.errorListNotifier!.value.isNotEmpty) {
        erroredProcessList.value = erroredProcessList.value.toList()
          ..add(notificationData);
      }
    }();
  }

  void setButtonKey(GlobalKey<ProcessNotificationsButtonState>? key) {
    buttonKey = key;
  }
}
