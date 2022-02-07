import 'package:asterfox/util/responsive.dart';
import 'package:flutter/material.dart';

import 'drawer.dart';

class BaseScreen extends StatelessWidget {
  const BaseScreen({
    required this.screen,
    this.appBar,
    this.footer,
    this.endDrawer,
    Key? key
  }) : super(key: key);

  final PreferredSizeWidget? appBar;
  final Widget screen;
  final StatelessWidget? footer;
  final StatelessWidget? endDrawer;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Row(children: [const SideMenu(), Expanded(child: screen,), endDrawer ?? const SizedBox(width: 0, height: 0)], mainAxisAlignment: MainAxisAlignment.start),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      body: Column(
        children: footer != null ? [screen, footer!] : [screen],
        mainAxisAlignment: MainAxisAlignment.end,
      ),
      drawer: const SideMenu(),
      endDrawer: endDrawer,
    );
  }
}
