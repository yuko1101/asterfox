import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/custom_colors.dart';
import '../utils/async_utils.dart';
import 'asterfox_dialog.dart';

Future<bool> _defaultOnWillPop() async => false;

class LoadingDialog extends StatelessWidget {
  static Future<void> showLoading({
    required BuildContext context,
    required Future future,
    Future<bool> Function() onWillPop = _defaultOnWillPop,
    ValueListenable<int>? percentageNotifier,
    bool barrierDismissible = false,
  }) async {
    final completer = Completer();
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        () async {
          await future;
          Navigator.of(context).pop();
          completer.complete();
        }();
        return LoadingDialog(
          onWillPop: onWillPop,
          percentageNotifier: percentageNotifier,
        );
      },
    );
    await completer.future;
  }

  static Future<void> showStreamLoading({
    required BuildContext context,
    required Stream<int> stream,
    Future<bool> Function() onWillPop = _defaultOnWillPop,
    bool barrierDismissible = false,
  }) async {
    final completer = Completer();
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        stream.listen((event) {}, onDone: () {
          Navigator.of(context).pop();
          completer.complete();
        });
        return LoadingDialog(
          onWillPop: onWillPop,
          percentageNotifier: stream.toValueNotifier(0),
        );
      },
    );
    await completer.future;
  }

  const LoadingDialog({
    this.onWillPop = _defaultOnWillPop,
    this.percentageNotifier,
    super.key,
  });

  final Future<bool> Function() onWillPop;
  final ValueListenable<int>? percentageNotifier;

  @override
  Widget build(BuildContext context) {
    if (percentageNotifier != null) {
      return AsterfoxDialog(
        child: SizedBox(
          height: 60,
          width: 60,
          child: Center(
            child: ValueListenableBuilder<int>(
              valueListenable: percentageNotifier!,
              builder: (context, value, child) => CircularProgressIndicator(
                color: CustomColors.getColor("accent"),
                value: value.toDouble() / 100,
              ),
            ),
          ),
        ),
      );
    }
    return AsterfoxDialog(
      child: SizedBox(
        height: 60,
        width: 60,
        child: Center(
          child: CircularProgressIndicator(
            color: CustomColors.getColor("accent"),
          ),
        ),
      ),
    );
  }
}
