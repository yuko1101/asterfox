import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../main.dart';
import '../../data/custom_colors.dart';
import '../../data/settings_data.dart';
import '../../system/firebase/cloud_firestore.dart';
import '../../system/git.dart';
import '../../system/theme/theme.dart';
import '../../utils/network_utils.dart';
import '../../utils/pair.dart';
import '../../widget/loading_dialog.dart';
import '../../widget/screen/scaffold_screen.dart';
import '../login_screen.dart';

class SettingsScreen extends ScaffoldScreen {
  const SettingsScreen({super.key})
      : super(
          body: const _MainSettingsScreen(),
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
      title: Text(AppLocalizations.of(context)!.settings),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: AppLocalizations.of(context)!.go_back,
      ),
    );
  }
}

class _MainSettingsScreen extends StatefulWidget {
  const _MainSettingsScreen({super.key});

  @override
  State<_MainSettingsScreen> createState() => _MainSettingsScreenState();
}

class _MainSettingsScreenState extends State<_MainSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final restartRequiredText = TextSpan(
      text: AppLocalizations.of(context)!.restart_required,
      style: const TextStyle(color: Colors.red),
    );

    return Scaffold(
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(AppLocalizations.of(context)!.general_settings),
            tiles: [
              SettingsTile.navigation(
                title: Text(AppLocalizations.of(context)!.theme),
                description: Text(AppTheme.themes
                    .map((theme) => theme.themeDetails.name)
                    .map((name) =>
                        AppLocalizations.of(context)!.theme_names(name))
                    .join(AppLocalizations.of(context)!.list_separator)),
                onPressed: (context) {
                  Navigator.of(context).pushNamed("/settings/theme");
                },
                trailing: const Icon(Icons.keyboard_arrow_right),
              )
            ],
          ),
          SettingsSection(
            title: Text(AppLocalizations.of(context)!.useful_functions),
            tiles: [
              SettingsTile.switchTile(
                title: Text(AppLocalizations.of(context)!.auto_download),
                description: Text(
                    AppLocalizations.of(context)!.auto_download_description),
                initialValue: SettingsData.getValue(key: "autoDownload"),
                activeSwitchColor: CustomColors.getColor("accent"),
                onToggle: (value) {
                  setState(() {
                    SettingsData.settings
                        .set(key: "autoDownload", value: value);
                    SettingsData.save();
                  });
                },
              ),
              SettingsTile.switchTile(
                title:
                    Text(AppLocalizations.of(context)!.disable_interruptions),
                description: RichText(
                  text: TextSpan(
                    text:
                        "${AppLocalizations.of(context)!.disable_interruptions_description}\n",
                    style: TextStyle(
                        color: Theme.of(context).extraColors.secondary),
                    children: [
                      restartRequiredText,
                    ],
                  ),
                ),
                initialValue:
                    SettingsData.getValue(key: "disableInterruptions"),
                activeSwitchColor: CustomColors.getColor("accent"),
                onToggle: (value) {
                  setState(() {
                    SettingsData.settings
                        .set(key: "disableInterruptions", value: value);
                    SettingsData.save();
                  });
                },
              ),
              SettingsTile.navigation(
                title: Text(AppLocalizations.of(context)!.audio_channel),
                description: RichText(
                  text: TextSpan(
                    text:
                        "${AppLocalizations.of(context)!.audio_channels(SettingsData.getValue(key: "audioChannel"))}\n",
                    style: TextStyle(
                        color: Theme.of(context).extraColors.secondary),
                    children: [
                      restartRequiredText,
                    ],
                  ),
                ),
                onPressed: (context) {
                  Navigator.of(context).pushNamed("/settings/audioChannel");
                },
                trailing: const Icon(Icons.keyboard_arrow_right),
              )
            ],
          ),
          if (shouldInitializeFirebase)
            SettingsSection(
              tiles: [
                SettingsTile(
                  title: Text(AppLocalizations.of(context)!.logout),
                  description: Text(FirebaseAuth.instance.currentUser!.email ??
                      FirebaseAuth.instance.currentUser!.displayName!),
                  leading: const Icon(Icons.logout),
                  onPressed: (context) async {
                    if (!NetworkUtils.networkConnected()) {
                      // TODO: multi-lang
                      Fluttertoast.showToast(
                          msg: "You cannot sign out when offline.");
                      return;
                    }

                    final future = () async {
                      await CloudFirestoreManager.cancelListeners();
                      GoogleSignInWidget.googleSignIn.disconnect();
                      FirebaseAuth.instance.signOut();
                    }();

                    await LoadingDialog.showLoading(
                      context: context,
                      future: future,
                    );
                  },
                ),
              ],
            ),
          SettingsSection(
            tiles: [
              SettingsTile(
                title: Text(AppLocalizations.of(context)!.app_info),
                description: FutureBuilder<Pair<String, String>>(
                  future: getGitInfo(),
                  builder: (context, snapshot) {
                    return snapshot.data == null
                        ? const Text("")
                        : GestureDetector(
                            child: Text(
                              "${snapshot.data!.first}/${snapshot.data!.second}",
                            ),
                            onLongPress: () {
                              Clipboard.setData(
                                ClipboardData(text: snapshot.data!.second),
                              );
                              Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context)!
                                      .copied_to_clipboard);
                            });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
