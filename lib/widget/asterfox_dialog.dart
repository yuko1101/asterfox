import 'package:asterfox/system/theme/theme.dart';
import 'package:flutter/material.dart';

Future<bool> defaultOnWillPop() async => true;

class AsterfoxDialog extends StatelessWidget {
  const AsterfoxDialog({
    required this.child,
    this.onWillPop = defaultOnWillPop,
    super.key,
  });
  final Widget child;
  final Future<bool> Function() onWillPop;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Center(
        child: Material(
          elevation: 24.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: Theme.of(context).extraColors.themeColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }
}
