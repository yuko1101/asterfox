import 'package:asterfox/main.dart';
import 'package:asterfox/theme/theme.dart';
import 'package:flutter/material.dart';
class ThemeWidget extends StatelessWidget {
  const ThemeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: themeNotifier,
        builder: (_, theme, __) => widget(context, themes[theme]!)
    );
  }

  Widget widget(BuildContext context, ThemeData theme) {
    return Container();
  }
}
