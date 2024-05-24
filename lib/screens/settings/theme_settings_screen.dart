import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../data/custom_colors.dart';
import '../../main.dart';
import '../../system/theme/theme.dart';
import '../../widget/screen/scaffold_screen.dart';

class ThemeSettingsScreen extends ScaffoldScreen {
  const ThemeSettingsScreen({super.key});

  @override
  PreferredSizeWidget appBar(BuildContext context) => const _AppBar();

  @override
  Widget body(BuildContext context) => const _ThemeChoice();
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(l10n.value.theme),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.value.go_back,
      ),
    );
  }
}

class _ThemeChoice extends StatefulWidget {
  const _ThemeChoice();

  @override
  State<_ThemeChoice> createState() => _ThemeChoiceState();
}

class _ThemeChoiceState extends State<_ThemeChoice> {
  @override
  Widget build(BuildContext context) {
    return SettingsList(
      sections: [
        SettingsSection(
          title: Text(l10n.value.theme),
          tiles: AppTheme.themes
              .map((theme) => theme.themeDetails.name)
              .map((name) => RadioListTile(
                  title: Text(l10n.value.theme_names(name)),
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
