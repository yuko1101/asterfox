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
  final PreferredSizeWidget? endDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      body: screen,
      drawer: const SideMenu(),
      endDrawer: endDrawer,
    );
  }
}
