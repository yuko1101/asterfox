import 'package:flutter/material.dart';

import '../../utils/responsive.dart';
import 'screen_interface.dart';

abstract class ScaffoldScreen extends StatelessWidget implements IScreen {
  const ScaffoldScreen({
    super.key,
  });

  /// The app bar of the screen which is displayed on top of the screen.
  PreferredSizeWidget? appBar(BuildContext context) {
    return null;
  }

  /// The main content of the screen.
  Widget body(BuildContext context);

  /// The footer of the screen which is displayed at the bottom of the screen.
  Widget? footer(BuildContext context) {
    return null;
  }

  /// The endDrawer of the screen which is at the right side of the screen.
  /// You can drag the endDrawer to open it.
  Widget? endDrawer(BuildContext context) {
    return null;
  }

  Widget? drawer(BuildContext context) {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final appBar = this.appBar(context);
    final body = this.body(context);
    final footer = this.footer(context);
    final endDrawer = this.endDrawer(context);
    final drawer = this.drawer(context);

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
                  if (drawer != null) drawer,
                  Expanded(child: body),
                  if (endDrawer != null) endDrawer,
                ],
              ),
            ),
            if (footer != null) footer,
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
            ? [Expanded(child: body), footer]
            : [Expanded(child: body)],
      ),
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }
}
