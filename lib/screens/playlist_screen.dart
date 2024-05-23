import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../music/playlist/playlist.dart';
import '../widget/playlist_widget.dart';
import '../widget/screen/scaffold_screen.dart';
import 'asterfox_screen.dart';

class PlaylistInfoScreen extends ScaffoldScreen {
  PlaylistInfoScreen(AppPlaylist playlist, {super.key})
      : super(
            appBar: const PlaylistInfoAppBar(),
            body: PlaylistInfoMainScreen(playlist),
            drawer: const AsterfoxSideMenu());
}

class PlaylistInfoAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PlaylistInfoAppBar({super.key});

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

class PlaylistInfoMainScreen extends StatefulWidget {
  const PlaylistInfoMainScreen(this.playlist, {super.key});

  final AppPlaylist playlist;

  @override
  State<PlaylistInfoMainScreen> createState() => _PlaylistInfoMainScreenState();
}

class _PlaylistInfoMainScreenState extends State<PlaylistInfoMainScreen> {
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
