import 'dart:async';

import 'package:asterfox/screens/settings/settings_screen.dart';
import 'package:asterfox/screens/song_history_screen.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/drawer.dart';
import 'package:easy_app/screen/main_screen.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'debug_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AsterfoxScreen extends StatelessWidget {
  const AsterfoxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          Fluttertoast.showToast(msg: Language.getText("something_went_wrong"));
          return AuthScreen();
        } else if (!snapshot.hasData) {
          return AuthScreen();
        } else {
          final User user = snapshot.data!;

          if (!user.emailVerified) {
            // TODO: find better solution
            Future.delayed(const Duration(milliseconds: 50),
                () => showVerifyEmailDialog(context));
          }

          return const AsterfoxMainScreen();
        }
      },
    );
  }

  void showVerifyEmailDialog(BuildContext context) {
    // TODO: better dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text(Language.getText("verify_email")),
          actions: [
            TextButton(
              child: Text(Language.getText("send")),
              onPressed: () {
                FirebaseAuth.instance.currentUser!.sendEmailVerification();
              },
            )
          ],
        ),
      ),
    );

    // check email verification every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) {
      Future.sync(() async {
        await FirebaseAuth.instance.currentUser!.reload();
        if (FirebaseAuth.instance.currentUser!.emailVerified) {
          timer.cancel();
          Navigator.pop(context);
        }
      });
    });
  }
}

class AsterfoxMainScreen extends StatelessWidget {
  const AsterfoxMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainScreen(
      sideMenu: SideMenu(
        appIcon: Image.asset(
          "assets/images/asterfox.png",
          scale: 0.1,
        ),
        title: const Text("Asterfox", textScaleFactor: 1.3),
        items: [
          SideMenuItem(
            title: const Text("Home"),
            icon: const Icon(Icons.home),
            onPressed: () {
              if (EasyApp.currentScreen is HomeScreen) return;
              EasyApp.pushPage(context, HomeScreen());
            },
          ),
          SideMenuItem(
            title: const Text("Playlist"),
            icon: const Icon(Icons.playlist_play),
            onPressed: () {},
          ),
          SideMenuItem(
            title: const Text("History"),
            icon: const Icon(Icons.replay),
            onPressed: () {
              if (EasyApp.currentScreen is SongHistoryScreen) return;
              EasyApp.pushPage(context, SongHistoryScreen());
            },
          ),
          SideMenuItem(
            title: const Text("Settings"),
            icon: const Icon(Icons.settings),
            onPressed: () {
              if (EasyApp.currentScreen is SettingsScreen) return;
              EasyApp.pushPage(context, SettingsScreen());
            },
          ),
          SideMenuItem(
            title: const Text("Debug"),
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              if (EasyApp.currentScreen is DebugScreen) return;
              EasyApp.pushPage(context, const DebugScreen());
            },
          )
        ],
      ),
    );
  }
}
