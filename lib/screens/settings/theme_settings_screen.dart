import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/screens/settings/settings_screen.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screen.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import 'package:asterfox/system/theme/theme.dart';

class ThemeSettingsScreen extends BaseScreen {
  ThemeSettingsScreen() : super(
    screen: const _ThemeChoice(),
    appBar: const _AppBar(),
    previousPage: SettingsScreen()
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
      title: Text(Language.getText("theme")),
      leading: IconButton(
        onPressed: () => EasyApp.popPage(context),
        icon: const Icon(Icons.arrow_back),
        tooltip: Language.getText("go_back"),
      ),
    );
  }
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
            title: Text(Language.getText("theme")),
            tiles: AppTheme.themes.keys.map((key) =>
                RadioListTile(
                  title: Text(Language.getText("theme_$key")),
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