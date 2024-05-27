import 'package:flutter/material.dart';

import '../../utils/responsive.dart';
import 'screen_interface.dart';

abstract class ScaffoldScreen extends StatelessWidget
    implements IScreen, IScaffoldScreen {
  const ScaffoldScreen({
    super.key,
  });

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget? footer(BuildContext context) => null;

  @override
  Widget? endDrawer(BuildContext context) => null;

  @override
  Widget? drawer(BuildContext context) => null;

  @override
  Widget build(BuildContext context) => buildScaffold(context, this);
}

abstract class IScaffoldScreen {
  /// The app bar of the screen which is displayed on top of the screen.
  PreferredSizeWidget? appBar(BuildContext context);

  /// The main content of the screen.
  Widget body(BuildContext context);

  /// The footer of the screen which is displayed at the bottom of the screen.
  Widget? footer(BuildContext context);

  /// The endDrawer of the screen which is at the right side of the screen.
  /// You can drag the endDrawer to open it.
  Widget? endDrawer(BuildContext context);

  Widget? drawer(BuildContext context);
}

Widget buildScaffold(BuildContext context, IScaffoldScreen screen) {
  final appBar = screen.appBar(context);
  final body = screen.body(context);
  final footer = screen.footer(context);
  final endDrawer = screen.endDrawer(context);
  final drawer = screen.drawer(context);

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
