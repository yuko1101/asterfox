import 'package:flutter/material.dart';

import '../main.dart';
import '../music/playlist/playlist.dart';
import '../widget/playlist_widget.dart';
import '../widget/screen/scaffold_screen.dart';
import 'asterfox_screen.dart';

class PlaylistInfoScreen extends ScaffoldScreen {
  const PlaylistInfoScreen(this.playlist, {super.key});

  final AppPlaylist playlist;

  @override
  PreferredSizeWidget appBar(BuildContext context) => const _AppBar();

  @override
  Widget body(BuildContext context) => _PlaylistInfo(playlist);

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
      title: Text(l10n.value.playlist),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.value.go_back,
      ),
    );
  }
}

class _PlaylistInfo extends StatefulWidget {
  const _PlaylistInfo(this.playlist);

  final AppPlaylist playlist;

  @override
  State<_PlaylistInfo> createState() => _PlaylistInfoState();
}

class _PlaylistInfoState extends State<_PlaylistInfo> {
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
