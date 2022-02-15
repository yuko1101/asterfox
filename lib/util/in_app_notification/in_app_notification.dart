import 'package:asterfox/util/in_app_notification/notification_widget.dart';
import 'package:flutter/material.dart';
import 'notification_data.dart';

final Tween<Offset> _offset = Tween(begin: const Offset(1, 0), end: const Offset(0, 0));

class InAppNotification extends StatelessWidget {
  InAppNotification({Key? key}) : super(key: key);

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final List<NotificationData> notifications = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Row(
          children: [
            const Spacer(),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2.5,
              child: IgnorePointer(
                child: ConstrainedBox(
                  constraints: const BoxConstraints.expand(),
                        child: SingleChildScrollView(
                          reverse: true,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              NotificationList(context)
                            ],
                          ),
                      ),
                ),
              )
            ),
            const SizedBox(width: 10)
          ]
        )
    );
  }


  Future<void> pushNotification(NotificationData notification, {Duration? duration}) async {
    notifications.add(notification);
    _listKey.currentState?.insertItem(notifications.length - 1);
    if (notification.progress == null) {
      Future.delayed(duration ?? const Duration(milliseconds: 2000), () {
        deleteNotification(notification.id);
      });
    } else {
      await notification.progress!.call();
      deleteNotification(notification.id);
    }
  }


  void deleteNotification(String id) {
    final int index = notifications.indexWhere((notification) => notification.id == id);
    if (index == -1) return;
    final deleted = notifications.removeAt(index);
    _listKey.currentState?.removeItem(
        index,
        (context, animation) => SlideTransition(
                position: animation.drive(_offset),
                child: NotificationWidget(notification: deleted)
            )
    );
  }

}



class NotificationList extends StatefulWidget {
  const NotificationList(this.parentContext, {Key? key}) : super(key: key);
  final BuildContext parentContext;
  @override
  _NotificationListState createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {


  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      key: (widget.parentContext.widget as InAppNotification)._listKey,
      initialItemCount: (widget.parentContext.widget as InAppNotification).notifications.length,
      itemBuilder: (context, index, animation) {
        return SlideTransition(
          child: NotificationWidget(notification: (widget.parentContext.widget as InAppNotification).notifications[index]),
          position: animation.drive(_offset),

        );
      }
    );
  }
}
