import 'package:asterfox/widget/process_notifications/process_notification_list.dart';
import 'package:asterfox/widget/process_notifications/process_notification_widget.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screens/scaffold_screen.dart';
import 'package:flutter/material.dart';

class ProcessNotificationScreen extends ScaffoldScreen {
  ProcessNotificationScreen(ProcessNotificationList processNotificationList,
      {super.key})
      : super(
          body: _MainScreen(processNotificationList),
          appBar: const _AppBar(),
        );
}

class _MainScreen extends StatelessWidget {
  const _MainScreen(this.processNotificationList, {super.key});
  final ProcessNotificationList processNotificationList;

  @override
  Widget build(BuildContext context) {
    // TODO: main screen
    return SafeArea(
      child: ValueListenableBuilder<List<ProcessNotificationData>>(
        valueListenable: processNotificationList.notificationsNotifier,
        builder: (context, value, child) => ListView.builder(
          itemBuilder: (context, index) => ProcessNotificationWidget(
            notificationData: value[index],
          ),
          itemCount: value.length,
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Running Processes"), // TODO: l10n
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          EasyApp.popPage(context);
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
