import 'package:asterfox/screen/base_screen.dart';
import 'package:asterfox/screen/page_manager.dart';
import 'package:asterfox/screen/screens/settings/theme_settings_screen.dart';
import 'package:asterfox/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../../main.dart';

class SettingsScreen extends BaseScreen {
  const SettingsScreen() : super(
    screen: const _MainSettingsScreen(),
  );
}

class _MainSettingsScreen extends StatelessWidget {
  const _MainSettingsScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text("基本設定"),
            tiles: [
              SettingsTile.navigation(
                title: const Text("テーマ"),
                description: Text(themeNames.values.join("、")),
                onPressed: (context) {
                  pushPage(context, ThemeSettingsScreen());
                },
              )
            ]
          )
        ],
      ),
    );
  }


}
