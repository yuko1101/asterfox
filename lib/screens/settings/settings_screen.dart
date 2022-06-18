import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screen.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../data/custom_colors.dart';
import '../../data/settings_data.dart';
import '../../system/theme/theme.dart';
import 'theme_settings_screen.dart';

class SettingsScreen extends BaseScreen {
  SettingsScreen()
      : super(
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
        onPressed: () => EasyApp.popPage(context),
        icon: const Icon(Icons.arrow_back),
        tooltip: Language.getText("go_back"),
      ),
    );
  }
}

class _MainSettingsScreen extends StatefulWidget {
  const _MainSettingsScreen({Key? key}) : super(key: key);

  @override
  State<_MainSettingsScreen> createState() => _MainSettingsScreenState();
}

class _MainSettingsScreenState extends State<_MainSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(Language.getText("general_settings")),
            tiles: [
              SettingsTile.navigation(
                title: Text(Language.getText("theme")),
                description: Text(AppTheme.themes.keys
                    .map((theme) => Language.getText("theme_$theme"))
                    .join(Language.getText("list_separator"))),
                onPressed: (context) {
                  EasyApp.pushPage(context, ThemeSettingsScreen());
                },
                trailing: const Icon(Icons.keyboard_arrow_right),
              )
            ],
          ),
          SettingsSection(
            title: Text(Language.getText("useful_functions")),
            tiles: [
              SettingsTile.switchTile(
                initialValue: SettingsData.getValue(key: "auto_download"),
                onToggle: (value) {
                  setState(() {
                    SettingsData.settings
                        .set(key: "auto_download", value: value);
                    SettingsData.save();
                  });
                },
                title: Text(Language.getText("auto_download")),
                activeSwitchColor: CustomColors.getColor("accent"),
                description:
                    Text(Language.getText("auto_download_description")),
              )
            ],
          )
        ],
      ),
    );
  }
}
