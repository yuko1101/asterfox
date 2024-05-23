import 'package:flutter/material.dart';

import '../notifiers_widget.dart';
import '../screen/scaffold_screen.dart';
import 'process_notification_list.dart';
import 'process_notification_widget.dart';

class ProcessNotificationScreen extends ScaffoldScreen {
  const ProcessNotificationScreen(this.processNotificationList, {super.key});

  final ProcessNotificationList processNotificationList;

  @override
  PreferredSizeWidget appBar(BuildContext context) => const _AppBar();

  @override
  Widget body(BuildContext context) => _MainScreen(processNotificationList);
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Running Processes"), // TODO: l10n
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _MainScreen extends StatelessWidget {
  const _MainScreen(this.processNotificationList);
  final ProcessNotificationList processNotificationList;

  @override
  Widget build(BuildContext context) {
    // TODO: main screen
    return SafeArea(
      child: DoubleNotifierWidget<List<ProcessNotificationData>,
          List<ProcessNotificationData>>(
        notifier1: processNotificationList.notificationsNotifier,
        notifier2: processNotificationList.erroredProcessList,
        builder: (context, running, errored, child) => ListView.builder(
          itemBuilder: (context, index) {
            if (running.length == index) {
              return ExpansionTile(
                title: const Text("Errored Processes"), // TODO: l10n
                children: errored
                    .map((e) => ProcessNotificationWidget(notificationData: e))
                    .toList(),
              );
            }
            return ProcessNotificationWidget(notificationData: running[index]);
          },
          itemCount: running.length + (errored.isNotEmpty ? 1 : 0),
        ),
      ),
    );
  }
}
