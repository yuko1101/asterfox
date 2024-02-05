import 'package:flutter/material.dart';

import '../system/theme/theme.dart';

class ThemeIconButton extends StatelessWidget {
  const ThemeIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, theme, _) {
        final themeDetails = theme.themeDetails;
        return IconButton(
          icon: Icon(themeDetails.icon),
          onPressed: () {
            AppTheme.setTheme(
              themeDetails.name == "dark" ? "light" : "dark",
            );
          },
        );
      },
    );
  }
}
