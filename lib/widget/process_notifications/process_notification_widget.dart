import 'package:asterfox/data/custom_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProcessNotificationData {
  ProcessNotificationData({
    required this.title,
    this.description,
    this.icon,
    required this.future,
    this.progressListenable,
    this.progressInPercentage = false,
    this.maxProgress,
  }) {
    assert((progressListenable != null && maxProgress != null) ||
        progressListenable == null);
  }
  final Widget title;
  final Widget? description;
  final Widget? icon;
  final Future future;
  final ValueListenable<int>? progressListenable;
  final bool progressInPercentage;
  final int? maxProgress;
}

class ProcessNotificationWidget extends StatelessWidget {
  const ProcessNotificationWidget({
    required this.notificationData,
    Key? key,
  }) : super(key: key);
  final ProcessNotificationData notificationData;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: SizedBox(
        height: 80,
        child: (notificationData.progressListenable != null)
            ? Column(
                // with progress
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        notificationData.title,
                      ],
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: notificationData.progressListenable!,
                    builder: (context, value, child) => LinearProgressIndicator(
                      color: CustomColors.getColor("accent"),
                      value: value.toDouble() /
                          notificationData.maxProgress!.toDouble(),
                    ),
                  )
                ],
              )
            : Row(
                // without progress
                children: [
                  notificationData.title,
                ],
              ),
      ),
    );
  }
}
