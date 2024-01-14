import 'package:flutter/material.dart';

import '../system/theme/theme.dart';

class AsterfoxDialog extends StatelessWidget {
  const AsterfoxDialog({
    required this.child,
    this.onPopInvoked,
    this.canPop = true,
    super.key,
  });
  final Widget child;
  final bool canPop;
  final Future<void> Function(bool)? onPopInvoked;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvoked: onPopInvoked,
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
