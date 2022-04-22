import 'package:asterfox/config/custom_colors.dart';
import 'package:asterfox/screen/base_screen.dart';
import 'package:asterfox/screen/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import 'package:asterfox/system/theme/theme.dart';

class ThemeSettingsScreen extends BaseScreen {
  ThemeSettingsScreen() : super(
    screen: const _ThemeChoice(),
    previousPage: SettingsScreen()
  );
}

class _ThemeChoice extends StatefulWidget {
  const _ThemeChoice({Key? key}) : super(key: key);

  @override
  State<_ThemeChoice> createState() => _ThemeChoiceState();
}

class _ThemeChoiceState extends State<_ThemeChoice> {

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      sections: [
        SettingsSection(
            title: const Text("テーマ"),
            tiles: AppTheme.themes.keys.map((key) =>
                RadioListTile(
                  title: Text(AppTheme.themeNames[key]!),
                  value: key,
                  groupValue: AppTheme.themeNotifier.value,
                  activeColor: Color(CustomColors.data.getValue("accent") as int),
                  onChanged: (value) {
                    setState(() {
                      AppTheme.setTheme(value as String);
                    });
                  }
                )
            ).map((radioListTile) =>
                CustomSettingsTile(
                  child: radioListTile
                )
            ).toList()
        ),
      ],
    );
  }
}