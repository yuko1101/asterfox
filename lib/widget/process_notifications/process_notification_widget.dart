import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/system/theme/theme.dart';
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
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: Material(
        elevation: 5,
        color: Theme.of(context).extraColors.themeColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 80,
          child: (notificationData.progressListenable != null)
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ValueListenableBuilder<int>(
                    valueListenable: notificationData.progressListenable!,
                    builder: (context, value, child) => Column(
                      // with progress
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              notificationData.title,
                              const Spacer(),
                              Text(
                                notificationData.progressInPercentage
                                    ? "$value%"
                                    : "$value/${notificationData.maxProgress}",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).extraColors.secondary,
                                ),
                              )
                            ],
                          ),
                        ),
                        if (notificationData.description != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: notificationData.description!,
                          ),
                        const Spacer(),
                        LinearProgressIndicator(
                          color: CustomColors.getColor("accent"),
                          value: value.toDouble() /
                              notificationData.maxProgress!.toDouble(),
                          backgroundColor: Colors.black12,
                        ),
                      ],
                    ),
                  ),
                )
              : Row(
                  // without progress
                  children: [
                    notificationData.title,
                  ],
                ),
        ),
      ),
    );
  }
}
