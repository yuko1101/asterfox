import 'package:asterfox/util/in_app_notification/notification_data.dart';
import 'package:asterfox/widget/theme_widget.dart';
import 'package:flutter/material.dart';

class NotificationWidget extends ThemeWidget {
  const NotificationWidget({
    required this.notification,
    Key? key
  }) : super(key: key);

  final NotificationData notification;

  @override
  Widget widget(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.backgroundColor
      ),
      child: Text(notification.title),
    );
  }
}
