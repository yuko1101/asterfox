import 'dart:async';

import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/drawer.dart';
import 'package:easy_app/screen/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';
import 'package:wear/wear.dart';

import '../main.dart';
import '../system/home_screen_music_manager.dart';
import '../system/sharing_intent.dart';
import '../widget/music_widgets/music_buttons.dart';
import '../widget/music_widgets/music_thumbnail.dart';
import '../widget/toast/toast_manager.dart';
import '../widget/toast/toast_widget.dart';
import 'debug_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'settings/settings_screen.dart';
import 'song_history_screen.dart';

class AsterfoxScreen extends StatelessWidget {
  const AsterfoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main App Screen (with Login Screen)
        shouldInitializeFirebase
            ? StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    // TODO: show toast
                    // Fluttertoast.showToast(
                    //     msg: AppLocalizations.of(context)!.something_went_wrong);
                    return AuthScreen();
                  } else if (!snapshot.hasData) {
                    return AuthScreen();
                  } else {
                    final User user = snapshot.data!;

                    if (!user.emailVerified) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showVerifyEmailDialog(context);
                      });
                    }

                    return const AsterfoxMainScreen();
                  }
                },
              )
            : const AsterfoxMainScreen(),
        // Toast Message Overlay
        const DefaultTextStyle(
          style: TextStyle(),
          child: Toast(),
        ),
      ],
    );
  }

  void showVerifyEmailDialog(BuildContext context) {
    // TODO: better dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(AppLocalizations.of(context)!.verify_email),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.send),
              onPressed: () {
                FirebaseAuth.instance.currentUser!
                    .sendEmailVerification()
                    .catchError((e) {
                  ToastManager.showSimpleToast(
                    // TODO: better message (such as "Too many request")
                    msg: Text(e.toString()),
                    icon: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                  );
                });
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.logout),
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
            )
          ],
        ),
      ),
    );

    // check email verification every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) {
      Future.sync(() async {
        final user = FirebaseAuth.instance.currentUser;
        await user?.reload();
        if (user != null && user.emailVerified) {
          timer.cancel();
          Navigator.pop(context);
        }
      });
    });
  }
}

class AsterfoxMainScreen extends StatefulWidget {
  const AsterfoxMainScreen({super.key});

  @override
  State<AsterfoxMainScreen> createState() => _AsterfoxMainScreenState();
}

class _AsterfoxMainScreenState extends State<AsterfoxMainScreen> {
  String? _sharedText;
  bool? _sharedTextIsInitial;

  @override
  void initState() {
    super.initState();

    ReceiveSharingIntent.getTextStream().listen((text) {
      setState(() {
        _sharedText = text;
        _sharedTextIsInitial = false;
      });
    });

    ReceiveSharingIntent.getInitialText().then((text) {
      setState(() {
        _sharedText = text;
        _sharedTextIsInitial = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sharedText != null && _sharedTextIsInitial != null) {
      SharingIntent.addSong(_sharedText!, _sharedTextIsInitial!, context);
      _sharedText = null;
      _sharedTextIsInitial = null;
    }

    if (isWearOS) {
      return DefaultTextStyle(
        style: const TextStyle(),
        child: WatchShape(
            builder: (_, shape, __) => AsterfoxMainWatchScreen(shape)),
      );
    }
    return MainScreen(
      sideMenu: SideMenu(
        appIcon: Image.asset(
          "assets/images/asterfox.png",
          scale: 0.1,
        ),
        title: const Text("Asterfox", textScaler: TextScaler.linear(1.3)),
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
            onPressed: () async {},
          ),
          SideMenuItem(
            title: const Text("History"),
            icon: const Icon(Icons.replay),
            onPressed: () {
              if (EasyApp.currentScreen is SongHistoryScreen) return;
              EasyApp.pushPage(context, const SongHistoryScreen());
            },
          ),
          SideMenuItem(
            title: const Text("Settings"),
            icon: const Icon(Icons.settings),
            onPressed: () {
              if (EasyApp.currentScreen is SettingsScreen) return;
              EasyApp.pushPage(context, const SettingsScreen());
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

// TODO: support sharing intent
class AsterfoxMainWatchScreen extends StatelessWidget {
  const AsterfoxMainWatchScreen(this.shape, {super.key});

  final WearShape shape;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: ConstrainedBox(
            constraints: const BoxConstraints.expand(),
            child: Stack(
              children: [
                const MusicThumbnail(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // CurrentSongTitle(),
                      // CurrentSongAuthor(),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          HomeScreenMusicManager.addSong(
                            key: const Uuid().v4(),
                            audioId: "ZRtdQ81jPUQ",
                            localizations: AppLocalizations.of(context)!,
                          );
                        },
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 高さ40に対してボタンのサイズを合わせ、横幅を10にすることで、ボタンアイコンの左右の余白を潰せる。
                          SizedBox(
                            width: 10,
                            height: 40,
                            child: FittedBox(
                              fit: BoxFit.fitHeight,
                              child: PreviousSongButton(),
                            ),
                          ),
                          PlayButton(),
                          SizedBox(
                            width: 10,
                            height: 40,
                            child: FittedBox(
                              fit: BoxFit.fitHeight,
                              child: NextSongButton(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            )),
      ),
    );
  }
}
