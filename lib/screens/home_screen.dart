import 'package:easy_app/screen/base_screens/scaffold_screen.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:easy_app/utils/responsive.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../music/manager/notifiers/audio_state_notifier.dart';
import '../system/theme/theme.dart';
import '../widget/music_footer.dart';
import '../widget/music_widgets/lyrics_button.dart';
import '../widget/music_widgets/volume_widget.dart';
import '../widget/playlist_widget.dart';
import '../widget/process_notifications/process_notification_list.dart';
import '../widget/search/song_search.dart';

class HomeScreen extends ScaffoldScreen {
  static late ProcessNotificationList processNotificationList;
  HomeScreen({
    super.key,
  }) : super(
          body: Builder(
            builder: (context) {
              final volumeWidgetKey = GlobalKey<VolumeWidgetState>();
              final volumeWidget = VolumeWidget(key: volumeWidgetKey);

              return Stack(
                children: [
                  ValueListenableBuilder<AudioState>(
                    valueListenable:
                        musicManager.audioStateManager.songsNotifier,
                    builder: (context, audioState, child) => PlaylistWidget(
                      songs: audioState.shuffledPlaylist,
                      currentSong: audioState.currentSong,
                      isLinked: true,
                      padding: const EdgeInsets.only(top: 15),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: LyricsButton(),
                  ),

                  // <------ Volume Button ------>
                  if (Responsive.isMobile(context))
                    ValueListenableBuilder<bool>(
                      valueListenable: volumeWidget.openedNotifier,
                      builder: (context, opened, _) {
                        if (opened) {
                          return GestureDetector(
                            onTap: volumeWidgetKey.currentState?.close,
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                  if (Responsive.isMobile(context))
                    Positioned(
                      bottom: 5,
                      left: 5,
                      child: volumeWidget,
                    ),
                  // <----------------------------->
                ],
              );
            },
          ),
          appBar: const HomeScreenAppBar(),
          footer: const MusicFooter(),
        );
}

class HomeScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeScreenAppBar({
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 35,
            width: 35,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.asset("assets/images/asterfox.png"),
            ),
          ),
          const SizedBox(width: 5),
          const Text("Asterfox")
        ],
      ),
      actions: [
        IconButton(
            onPressed: () async {
              final searchDelegate =
                  SongSearch(animationController: _menuIconAnimationController);
              _menuIconAnimationController.forward();
              await showSearch(context: context, delegate: searchDelegate)
                  .then((value) {
                _menuIconAnimationController.reverse();
              });
            },
            icon: const Icon(Icons.search)),
      ],
      leading: IconButton(
        onPressed: () => AppDrawerController(context).openDrawer(),
        icon: const AnimatedMenuIcon(),
        tooltip: Language.getText("menu"),
      ),
      bottom: AppBarDivider(
        height: 1,
        color: Theme.of(context).extraColors.primary.withOpacity(0.04),
      ),
    );
  }
}

class AppDrawerController {
  AppDrawerController(this.context);
  final BuildContext context;

  void openDrawer() {
    final ScaffoldState scaffoldState = Scaffold.of(context);
    if (!scaffoldState.isDrawerOpen) {
      FocusScope.of(context).requestFocus(FocusNode());
      scaffoldState.openDrawer();
    }
  }

  void openEndDrawer() {
    final ScaffoldState scaffoldState = Scaffold.of(context);
    if (scaffoldState.isEndDrawerOpen) {
      FocusScope.of(context).requestFocus(FocusNode());
      scaffoldState.openEndDrawer();
    }
  }
}

class AnimatedMenuIcon extends StatefulWidget {
  const AnimatedMenuIcon({super.key});

  @override
  State<AnimatedMenuIcon> createState() => AnimatedMenuIconState();
}

late AnimationController _menuIconAnimationController;

class AnimatedMenuIconState extends State<AnimatedMenuIcon>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _menuIconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedIcon(
        icon: AnimatedIcons.menu_arrow, progress: _menuIconAnimationController);
  }
}

class AppBarDivider extends Divider implements PreferredSizeWidget {
  AppBarDivider({
    double height = 16.0,
    super.endIndent,
    super.color,
    super.key,
  })  : assert(height >= 0.0),
        super(
          height: height,
        ) {
    _height = height;
  }

  late final double _height;

  @override
  Size get preferredSize => Size(double.infinity, _height);
}
