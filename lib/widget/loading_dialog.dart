import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/custom_colors.dart';
import 'asterfox_dialog.dart';

class LoadingDialog extends StatelessWidget {
  /// Shows a loading dialog until [future] has finished, and closes it whether
  /// [future] succeeds or fails. What [future] throws is thrown from here.
  ///
  /// The dialog is not closed by the back button unless [barrierDismissible].
  static Future<void> showLoading({
    required BuildContext context,
    required Future future,
    ValueListenable<int>? percentageNotifier,
    bool barrierDismissible = false,
  }) async {
    final navigator = Navigator.of(context);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => LoadingDialog(
        canPop: barrierDismissible,
        percentageNotifier: percentageNotifier,
      ),
    );
    navigator.push(route);
    try {
      await future;
    } finally {
      // Only this dialog is closed, even if something was opened over it.
      if (route.isCurrent) {
        navigator.pop();
      } else if (route.isActive) {
        navigator.removeRoute(route);
      }
    }
  }

  const LoadingDialog({
    this.canPop = false,
    this.percentageNotifier,
    super.key,
  });

  final bool canPop;
  final ValueListenable<int>? percentageNotifier;

  @override
  Widget build(BuildContext context) {
    final color = CustomColors.getColor("accent");
    return AsterfoxDialog(
      canPop: canPop,
      child: SizedBox(
        height: 60,
        width: 60,
        child: Center(
          child: percentageNotifier == null
              ? CircularProgressIndicator(color: color)
              : ValueListenableBuilder<int>(
                  valueListenable: percentageNotifier!,
                  builder: (context, value, child) => CircularProgressIndicator(
                    color: color,
                    value: value / 100,
                  ),
                ),
        ),
      ),
    );
  }
}
