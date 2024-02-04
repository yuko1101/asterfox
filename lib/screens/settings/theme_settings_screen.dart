import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../data/custom_colors.dart';
import '../../system/theme/theme.dart';
import '../../widget/screen/scaffold_screen.dart';

class ThemeSettingsScreen extends ScaffoldScreen {
  const ThemeSettingsScreen({super.key})
      : super(
          body: const _ThemeChoice(),
          appBar: const _AppBar(),
        );
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.theme),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: AppLocalizations.of(context)!.go_back,
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
          title: Text(AppLocalizations.of(context)!.theme),
          tiles: AppTheme.themes
              .map((theme) => theme.themeDetails.name)
              .map((name) => RadioListTile(
                  title: Text(AppLocalizations.of(context)!.theme_names(name)),
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
