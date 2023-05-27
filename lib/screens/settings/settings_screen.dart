import 'package:asterfox/screens/login_screen.dart';
import 'package:asterfox/system/firebase/cloud_firestore.dart';
import 'package:asterfox/widget/loading_dialog.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screens/scaffold_screen.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:easy_app/utils/network_utils.dart';
import 'package:easy_app/utils/pair.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../main.dart';
import '../../data/custom_colors.dart';
import '../../data/settings_data.dart';
import '../../system/git.dart';
import '../../system/theme/theme.dart';
import 'theme_settings_screen.dart';

class SettingsScreen extends ScaffoldScreen {
  const SettingsScreen({
    Key? key,
  }) : super(
          body: const _MainSettingsScreen(),
          appBar: const _AppBar(),
          key: key,
        );
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
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
                description: Text(AppTheme.themes
                    .map((theme) => theme.themeDetails.name)
                    .map((name) => Language.getText("theme_$name"))
                    .join(Language.getText("list_separator"))),
                onPressed: (context) {
                  EasyApp.pushPage(context, const ThemeSettingsScreen());
                },
                trailing: const Icon(Icons.keyboard_arrow_right),
              )
            ],
          ),
          SettingsSection(
            title: Text(Language.getText("useful_functions")),
            tiles: [
              SettingsTile.switchTile(
                title: Text(Language.getText("auto_download")),
                description:
                    Text(Language.getText("auto_download_description")),
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
            ],
          ),
          if (shouldInitializeFirebase)
            SettingsSection(
              tiles: [
                SettingsTile(
                  title: Text(Language.getText("logout")),
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
                title: Text(Language.getText("app_info")),
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
                                  msg: Language.getText("copied_to_clipboard"));
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
