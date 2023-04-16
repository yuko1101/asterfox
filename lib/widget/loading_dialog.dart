import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/widget/asterfox_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> _defaultOnWillPop() async => false;

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({
    this.onWillPop = _defaultOnWillPop,
    this.percentageNotifier,
    super.key,
  });

  final Future<bool> Function() onWillPop;
  final ValueNotifier<int>? percentageNotifier;

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
