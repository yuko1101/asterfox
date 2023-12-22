import 'package:flutter/cupertino.dart';

import 'process_notification_widget.dart';

class ProcessNotificationList {

  final ValueNotifier<List<ProcessNotificationData>> notificationsNotifier =
      ValueNotifier([]);

  final ValueNotifier<List<ProcessNotificationData>> erroredProcessList =
      ValueNotifier([]);

  Future<void> push(ProcessNotificationData notificationData) async {
    notificationsNotifier.value = [
      ...notificationsNotifier.value,
      notificationData
    ];

    await notificationData.future;

    notificationsNotifier.value = [...notificationsNotifier.value]
      ..remove(notificationData);

    if (notificationData.errorListNotifier != null &&
        notificationData.errorListNotifier!.value.isNotEmpty) {
      erroredProcessList.value = erroredProcessList.value.toList()
        ..add(notificationData);
    }
  }
}
