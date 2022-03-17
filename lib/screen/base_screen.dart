import 'package:asterfox/util/responsive.dart';
import 'package:flutter/material.dart';

import 'drawer.dart';

class BaseScreen {
  const BaseScreen({
    required this.screen,
    this.appBar,
    this.footer,
    this.endDrawer,
    this.previousPage,
  });

  final PreferredSizeWidget? appBar;
  final Widget screen;
  final StatelessWidget? footer;
  final StatelessWidget? endDrawer;
  final BaseScreen? previousPage;
}
