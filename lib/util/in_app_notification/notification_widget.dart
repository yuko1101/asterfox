import 'package:asterfox/config/custom_colors.dart';
import 'package:asterfox/util/in_app_notification/notification_data.dart';
import 'package:flutter/material.dart';

class NotificationWidget extends StatelessWidget {
  const NotificationWidget({
    required this.notification,
    Key? key
  }) : super(key: key);

  final NotificationData notification;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CustomColors.getColor("accent")),
                  color: Theme.of(context).backgroundColor,
              ),
              child: notification.title,
            ),
          ],
        ),
      ],
    );
  }
}
