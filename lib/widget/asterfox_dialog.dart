import 'package:asterfox/system/theme/theme.dart';
import 'package:flutter/material.dart';

class AsterfoxDialog extends StatelessWidget {
  const AsterfoxDialog({required this.child, this.canPop = true, super.key});
  final Widget child;
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => canPop,
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
