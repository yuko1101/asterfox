import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../music/playlist/playlist.dart';
import '../widget/playlist_widget.dart';
import '../widget/screen/scaffold_screen.dart';
import 'asterfox_screen.dart';

class PlaylistScreen extends ScaffoldScreen {
  PlaylistScreen(AppPlaylist playlist, {super.key})
      : super(
            appBar: const PlaylistAppBar(),
            body: PlaylistMainScreen(playlist),
            drawer: const AsterfoxSideMenu());
}

class PlaylistAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PlaylistAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.playlist),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: AppLocalizations.of(context)!.go_back,
      ),
    );
  }
}

class PlaylistMainScreen extends StatefulWidget {
  const PlaylistMainScreen(this.playlist, {super.key});

  final AppPlaylist playlist;

  @override
  State<PlaylistMainScreen> createState() => _PlaylistMainScreenState();
}

class _PlaylistMainScreenState extends State<PlaylistMainScreen> {
  @override
  Widget build(BuildContext context) {
    final songs = widget.playlist.musicDataList;
    return PlaylistWidget(
      songs: songs,
      onRemove: (i, _) {
        songs.removeAt(i);
      },
    );
  }
}
