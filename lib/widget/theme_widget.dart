import 'package:asterfox/main.dart';
import 'package:asterfox/theme/theme.dart';
import 'package:flutter/material.dart';
class ThemeWidget extends StatelessWidget {
  const ThemeWidget({this.builder, Key? key}) : super(key: key);
  final Widget Function(BuildContext, ThemeData)? builder;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: themeNotifier,
        builder: (_, theme, __) => builder?.call(context, themes[theme]!) ?? themeBuild(context, themes[theme]!)
    );
  }

  Widget themeBuild(BuildContext context, ThemeData theme) {
    return Container();
  }
}
