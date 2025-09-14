import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
import '../asterfox_screen.dart';
import '../auth_screen.dart';

class SettingsScreen extends ScaffoldScreen {
  const SettingsScreen({super.key});

  @override
  PreferredSizeWidget appBar(BuildContext context) => const _AppBar();

  @override
  Widget body(BuildContext context) => const _MainSettingsScreen();

  @override
  Widget drawer(BuildContext context) => const AsterfoxSideMenu();
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(l10n.value.settings),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.value.go_back,
      ),
    );
  }
}

class _MainSettingsScreen extends StatefulWidget {
  const _MainSettingsScreen();

  @override
  State<_MainSettingsScreen> createState() => _MainSettingsScreenState();
}

class _MainSettingsScreenState extends State<_MainSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final restartRequiredText = TextSpan(
      text: l10n.value.restart_required,
      style: const TextStyle(color: Colors.red),
    );

    return Scaffold(
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(l10n.value.general_settings),
            tiles: [
              SettingsTile.navigation(
                title: Text(l10n.value.theme),
                description: Text(AppTheme.themes
                    .map((theme) => theme.themeDetails.name)
                    .map((name) => l10n.value.theme_names(name))
                    .join(l10n.value.list_separator)),
                onPressed: (context) {
                  Navigator.of(context).pushNamed("/settings/theme");
                },
                trailing: const Icon(Icons.keyboard_arrow_right),
              )
            ],
          ),
          SettingsSection(
            title: Text(l10n.value.useful_functions),
            tiles: [
              SettingsTile.switchTile(
                title: Text(l10n.value.auto_download),
                description: Text(l10n.value.auto_download_description),
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
                title: Text(l10n.value.disable_interruptions),
                description: RichText(
                  text: TextSpan(
                    text: "${l10n.value.disable_interruptions_description}\n",
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
                title: Text(l10n.value.audio_channel),
                description: RichText(
                  text: TextSpan(
                    text:
                        "${l10n.value.audio_channels(SettingsData.getValue(key: "audioChannel"))}\n",
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
                  title: Text(l10n.value.logout),
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
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      await CloudFirestoreManager.cancelListeners();
                      await CloudFirestoreManager.waitForTasks();
                      final signInState = GoogleSignInWidget.signInState.value;

                      if (GoogleSignInWidget.isAvailable &&
                          signInState
                              is GoogleSignInAuthenticationEventSignIn) {
                        GoogleSignIn.instance.disconnect();
                      }
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
                title: Text(l10n.value.app_info),
                description: FutureBuilder<Pair<String, String>>(
                  future: getGitInfo(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }
                    return snapshot.data == null
                        ? const Text("No info")
                        : GestureDetector(
                            child: Text(
                              "${snapshot.data!.first}/${snapshot.data!.second}",
                            ),
                            onLongPress: () {
                              Clipboard.setData(
                                ClipboardData(text: snapshot.data!.second),
                              );
                              Fluttertoast.showToast(
                                  msg: l10n.value.copied_to_clipboard);
                            },
                          );
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
