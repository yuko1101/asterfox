import 'package:flutter/material.dart';

import 'scaffold_screen.dart';
import 'screen_interface.dart';

abstract class StatefulScaffoldScreen extends StatefulWidget
    implements IScreen {
  const StatefulScaffoldScreen({super.key});

  @override
  State<StatefulScaffoldScreen> createState();
}

abstract class StatefulScaffoldScreenState<T extends StatefulScaffoldScreen> extends State<T>
    implements IScaffoldScreen {
  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget? footer(BuildContext context) => null;

  @override
  Widget? endDrawer(BuildContext context) => null;

  @override
  Widget? drawer(BuildContext context) => null;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(context, this);
  }
}
