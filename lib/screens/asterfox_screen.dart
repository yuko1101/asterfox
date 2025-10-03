import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../music/music_data/music_data.dart';
import '../system/home_screen_music_manager.dart';
import '../utils/responsive.dart';
import '../widget/music_widgets/music_buttons.dart';
import '../widget/music_widgets/music_thumbnail.dart';
import '../widget/theme_icon_button.dart';
import '../widget/toast/toast_manager.dart';
import '../widget/toast/toast_widget.dart';
import '../widget/utility_widgets/scrollable_detector.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

class AsterfoxScreen extends StatelessWidget {
  const AsterfoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!l10n.isInitialized || l.localeName != l10n.value.localeName) {
      l10n.value = l;
    }

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
                    //     msg: localization.value.something_went_wrong);
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
          title: Text(l10n.value.verify_email),
          actions: [
            TextButton(
              child: Text(l10n.value.send),
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
              child: Text(l10n.value.logout),
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
          Navigator.of(context).pop();
        }
      });
    });
  }
}

class AsterfoxMainScreen extends StatelessWidget {
  const AsterfoxMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // if (isWearOS) {
    //   return DefaultTextStyle(
    //     style: const TextStyle(),
    //     child: WatchShape(
    //         builder: (_, shape, __) => AsterfoxMainWatchScreen(shape)),
    //   );
    // }
    return const HomeScreen();
  }
}

// TODO: support sharing intent
class AsterfoxMainWatchScreen extends StatelessWidget {
  const AsterfoxMainWatchScreen(/* this.shape , */ {super.key});

  // final WearShape shape;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                            caching: CachingEnabled.random(),
                            audioId: "ZRtdQ81jPUQ",
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

class AsterfoxSideMenu extends StatelessWidget {
  const AsterfoxSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return SizedBox(
      width:
          isDesktop ? 250 : min(320, MediaQuery.of(context).size.width * 0.8),
      child: Drawer(
        shape: isDesktop ? Border() : null,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: const _SideMenuContent(),
        ),
      ),
    );
  }
}

class _SideMenuContent extends StatefulWidget {
  const _SideMenuContent();

  @override
  State<_SideMenuContent> createState() => _SideMenuContentState();
}

class _SideMenuContentState extends State<_SideMenuContent> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    final items = [
      if (!isDesktop)
        DrawerHeader(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 30),
                Image.asset(
                  "assets/images/asterfox.png",
                  width: 40,
                  height: 40,
                ),
                SizedBox(width: 12),
                Text(
                  "Asterfox",
                  textScaler: TextScaler.linear(1.4),
                ),
              ],
            ),
          ),
        ),
      SideMenuItem(
        title: const Text("Home"),
        icon: const Icon(Icons.home),
        onPressed: () {
          Navigator.of(context).pushNamed(
            "/home",
          );
        },
      ),
      SideMenuItem(
        title: const Text("Playlist"),
        icon: const Icon(Icons.playlist_play),
        onPressed: () {
          Navigator.of(context).pushNamed(
            "/playlists",
          );
        },
      ),
      SideMenuItem(
        title: const Text("History"),
        icon: const Icon(Icons.replay),
        onPressed: () {
          Navigator.of(context).pushNamed(
            "/history",
          );
        },
      ),
      SideMenuItem(
        title: const Text("Settings"),
        icon: const Icon(Icons.settings),
        onPressed: () {
          Navigator.of(context).pushNamed(
            "/settings",
          );
        },
      ),
      SideMenuItem(
        title: const Text("Debug"),
        icon: const Icon(Icons.bug_report),
        onPressed: () {
          Navigator.of(context).pushNamed(
            "/debug",
          );
        },
      ),
    ];

    // TODO: 今のままだとスクロールが可能になるのは、ColumnとThemeIconButtonが重なったあとになってしまうため、Columnに余白を追加したいが可読性が悪くなってしまうため、それ専用のウィジェットを作成する。
    return ScrollableDetector(
        controller: _scrollController,
        builder: (context, isScrollable) {
          return isScrollable
              ? SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...items,
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 1,
                          left: 15,
                        ),
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: ThemeIconButton(),
                        ),
                      )
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Positioned(
                      bottom: MediaQuery.of(context).padding.bottom + 15,
                      left: 25,
                      child: const ThemeIconButton(),
                    ),
                    SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: items,
                      ),
                    ),
                  ],
                );
        });
  }
}

class SideMenuItem extends StatelessWidget {
  const SideMenuItem({
    required this.title,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    super.key,
  });

  final Widget title;
  final Icon icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ??
          Colors
              .transparent, // transparent traces the background color of SideBar.
      child: InkWell(
        child: ListTile(
          onTap: onPressed,
          horizontalTitleGap: 10,
          leading: icon,
          title: title,
        ),
      ),
    );
  }
}
