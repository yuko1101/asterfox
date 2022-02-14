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
  Widget themeBuild(BuildContext context, ThemeData theme) {
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
                  color: theme.textTheme.headline3?.color,
                  boxShadow: const [
                    BoxShadow() //TODO: Lightテーマは影と付けて見やすくする。Darkテーマは色を灰色にする
                  ]
              ),
              child: notification.title,
            ),
          ],
        ),
      ],
    );
  }
}
