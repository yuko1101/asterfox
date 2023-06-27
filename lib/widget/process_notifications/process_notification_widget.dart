import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/utils/result.dart';
import 'package:asterfox/widget/notifiers_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProcessNotificationData {
  ProcessNotificationData({
    required this.title,
    this.description,
    this.icon,
    required this.future,
    this.progressListenable,
    this.progressStream,
    this.progressInPercentage = false,
    this.maxProgress,
    this.maxProgressListenable,
    this.errorListNotifier,
  }) {
    if (progressListenable != null || progressStream != null) {
      assert(maxProgress != null || maxProgressListenable != null);
    }
  }
  final Widget title;
  final Widget? description;
  final Widget? icon;
  final Future future;
  final ValueListenable<int>? progressListenable;
  final Stream<int>? progressStream;
  final bool progressInPercentage;
  final int? maxProgress;
  final ValueListenable<int>? maxProgressListenable;
  final ValueListenable<List<ResultFailedReason>>? errorListNotifier;
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
        child: NullableNotifierWidget<List<ResultFailedReason>>(
          initialData: const [],
          notifier: notificationData.errorListNotifier,
          builder: (context, errorList) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: NullableNotifierWidget<int>(
              initialData: 0,
              stream: notificationData.progressStream,
              notifier: notificationData.progressListenable,
              builder: (context, value) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        notificationData.title,
                        const Spacer(),
                        NullableNotifierWidget<int?>(
                          initialData: null,
                          notifier: notificationData.maxProgressListenable,
                          builder: (context, max) {
                            max ??= notificationData.maxProgress!;
                            return _getProgressText(value, max, context);
                          },
                        ),
                      ],
                    ),
                  ),
                  notificationData.description != null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: notificationData.description!,
                        )
                      : const SizedBox(
                          height: 30,
                        ),
                  NullableNotifierWidget<int?>(
                    initialData: null,
                    notifier: notificationData.maxProgressListenable,
                    builder: (context, max) {
                      max ??= notificationData.maxProgress!;
                      return LinearProgressIndicator(
                        color: CustomColors.getColor("accent"),
                        value: value.toDouble() / max.toDouble(),
                        backgroundColor: Colors.black12,
                      );
                    },
                  ),
                  if (errorList.isNotEmpty)
                    ExpansionTile(
                      title: const Text("Errors"), // TODO: l10n
                      children: errorList
                          .map((e) => ExpansionTile(
                                title: Text(e.title),
                                children: [Text(e.description)],
                              ))
                          .toList(),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Text _getProgressText(int value, int max, BuildContext context) {
    return Text(
      notificationData.progressInPercentage
          ? "${(value.toDouble() / max.toDouble() * 100).toInt()}%"
          : "$value/$max",
      style: TextStyle(
        color: Theme.of(context).extraColors.secondary,
      ),
    );
  }
}
