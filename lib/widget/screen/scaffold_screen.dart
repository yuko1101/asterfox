import 'package:flutter/material.dart';

import '../../utils/responsive.dart';
import 'base_screen.dart';

class ScaffoldScreen extends BaseScreen {
  const ScaffoldScreen({
    required this.body,
    this.appBar,
    this.footer,
    this.endDrawer,
    this.drawer,
    super.key,
  });

  /// The app bar of the screen which is displayed on top of the screen.
  final PreferredSizeWidget? appBar;

  /// The main content of the screen.
  final Widget body;

  /// The footer of the screen which is displayed at the bottom of the screen.
  final Widget? footer;

  /// The endDrawer of the screen which is at the right side of the screen.
  /// You can drag the endDrawer to open it.
  final Widget? endDrawer;

  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (drawer != null) drawer!,
                  Expanded(child: body),
                  if (endDrawer != null) endDrawer!,
                ],
              ),
            ),
            if (footer != null) footer!,
          ],
        ),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: footer != null
            ? [Expanded(child: body), footer!]
            : [Expanded(child: body)],
      ),
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }
}
