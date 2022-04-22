import 'package:asterfox/system/theme/theme.dart';
import 'package:flutter/material.dart';
class ThemeWidget extends StatelessWidget {
  const ThemeWidget({this.builder, Key? key}) : super(key: key);
  final Widget Function(BuildContext, ThemeData)? builder;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: AppTheme.themeNotifier,
        builder: (_, theme, __) => builder?.call(context, AppTheme.themes[theme]!) ?? themeBuild(context, AppTheme.themes[theme]!)
    );
  }

  Widget themeBuild(BuildContext context, ThemeData theme) {
    return Container();
  }
}
