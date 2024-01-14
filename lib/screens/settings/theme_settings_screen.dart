import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screens/scaffold_screen.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../data/custom_colors.dart';
import '../../system/theme/theme.dart';
import 'settings_screen.dart';

class ThemeSettingsScreen extends ScaffoldScreen {
  const ThemeSettingsScreen({super.key})
      : super(
          body: const _ThemeChoice(),
          appBar: const _AppBar(),
          previousPage: const SettingsScreen(),
        );
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({super.key});

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
  const _ThemeChoice({super.key});

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
          tiles: AppTheme.themes
              .map((theme) => theme.themeDetails.name)
              .map((name) => RadioListTile(
                  title: Text(Language.getText("theme_$name")),
                  value: name,
                  groupValue: AppTheme.themeNotifier.value.themeDetails.name,
                  activeColor:
                      Color(CustomColors.data.getValue("accent") as int),
                  onChanged: (value) {
                    setState(
                      () {
                        AppTheme.setTheme(value as String);
                      },
                    );
                  }))
              .map((radioListTile) => CustomSettingsTile(child: radioListTile))
              .toList(),
        ),
      ],
    );
  }
}
