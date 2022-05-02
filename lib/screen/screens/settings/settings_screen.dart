import 'package:asterfox/screen/base_screen.dart';
import 'package:asterfox/screen/page_manager.dart';
import 'package:asterfox/screen/screens/home_screen.dart';
import 'package:asterfox/screen/screens/settings/theme_settings_screen.dart';
import 'package:asterfox/system/languages.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends BaseScreen {
  SettingsScreen() : super(
    screen: const _MainSettingsScreen(),
    appBar: const _AppBar(),
  );
}

class _AppBar extends StatelessWidget with PreferredSizeWidget {
  const _AppBar({
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(Language.getText("settings")),
      leading: IconButton(
        onPressed: () => PageManager.goBack(context),
        icon: const Icon(Icons.arrow_back),
        tooltip: "戻る",
      ),
    );
  }
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
                description: Text(AppTheme.themeNames.values.join("、")),
                onPressed: (context) {
                  PageManager.pushPage(context, ThemeSettingsScreen());
                },
                trailing: const Icon(Icons.keyboard_arrow_right),
              )
            ]
          )
        ],
      ),
    );
  }


}
