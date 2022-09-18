import 'package:asterfox/widget/toast/toast_widget.dart';
import 'package:flutter/material.dart';

class ToastManager {
  static Future<void> showSimpleToast(
      {Icon? icon, required Widget msg, required BuildContext context}) async {
    final givenWidget = icon == null
        ? msg
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [icon, const SizedBox(width: 15), msg],
          );
    final widget = Padding(
      padding: const EdgeInsets.all(8.0),
      child: givenWidget,
    );
    final toastWidget = getToastWidget(widget, context);
    final toastData = ToastData(
      message: toastWidget,
      duration: const Duration(seconds: 2),
    );
    await Toast.showToast(toastData);
  }

  static Widget getToastWidget(Widget widget, BuildContext context) {
    return Container(
      child: widget,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).backgroundColor,
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
