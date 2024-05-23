import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../data/custom_colors.dart';
import '../../data/settings_data.dart';
import '../../widget/screen/scaffold_screen.dart';

class AudioChannelSettingsScreen extends ScaffoldScreen {
  const AudioChannelSettingsScreen({
    super.key,
  });

  @override
  PreferredSizeWidget appBar(BuildContext context) => const _AppBar();

  @override
  Widget body(BuildContext context) => const _AudioChannelChoice();
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.audio_channel),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: AppLocalizations.of(context)!.go_back,
      ),
    );
  }
}

class _AudioChannelChoice extends StatefulWidget {
  const _AudioChannelChoice();

  @override
  State<_AudioChannelChoice> createState() => _AudioChannelChoiceState();
}

final audioChannels = [
  {
    "name": "media",
    "icon": Icons.music_note,
  },
  {
    "name": "call",
    "icon": Icons.call,
  },
  {
    "name": "call_speaker",
    "icon": Icons.speaker,
  },
  {
    "name": "notification",
    "icon": Icons.notifications,
  },
  {
    "name": "alarm",
    "icon": Icons.alarm,
  }
];

class _AudioChannelChoiceState extends State<_AudioChannelChoice> {
  @override
  Widget build(BuildContext context) {
    return SettingsList(
      sections: [
        SettingsSection(
          title: Text(AppLocalizations.of(context)!.audio_channel),
          tiles: audioChannels
              .map((audioChannel) => RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(audioChannel["icon"] as IconData),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(AppLocalizations.of(context)!
                            .audio_channels(audioChannel["name"] as String)),
                      ],
                    ),
                    value: audioChannel["name"] as String,
                    groupValue: SettingsData.getValue(key: "audioChannel"),
                    activeColor:
                        Color(CustomColors.data.getValue("accent") as int),
                    onChanged: (value) {
                      setState(() {
                        SettingsData.settings.set(
                          key: "audioChannel",
                          value: audioChannel["name"],
                        );
                        SettingsData.save();
                      });
                    },
                  ))
              .map((radioListTile) => CustomSettingsTile(child: radioListTile))
              .toList(),
        ),
      ],
    );
  }
}
