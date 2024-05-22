import 'package:flutter/material.dart';

import '../../system/theme/theme.dart';
import 'toast_widget.dart';

class ToastManager {
  static Future<void> showSimpleToast({
    Icon? icon,
    required Widget msg,
  }) async {
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
    final toastWidget = getToastWidget(widget);
    final toastData = ToastData(
      message: toastWidget,
      duration: const Duration(seconds: 2),
    );
    await Toast.showToast(toastData);
  }

  static Widget getToastWidget(Widget widget) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppTheme.themeNotifier.value.scaffoldBackgroundColor,
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: widget,
    );
  }
}
