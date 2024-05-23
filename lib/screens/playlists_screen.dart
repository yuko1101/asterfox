import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../data/playlist_data.dart';
import '../widget/playlist_card.dart';
import '../widget/screen/scaffold_screen.dart';
import 'asterfox_screen.dart';

class PlaylistsScreen extends ScaffoldScreen {
  const PlaylistsScreen({super.key})
      : super(
          appBar: const PlaylistsAppBar(),
          body: const PlaylistsMainScreen(),
          drawer: const AsterfoxSideMenu(),
        );
}

class PlaylistsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PlaylistsAppBar({super.key});

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

class PlaylistsMainScreen extends StatefulWidget {
  const PlaylistsMainScreen({super.key});

  @override
  State<PlaylistsMainScreen> createState() => _PlaylistsMainScreenState();
}

class _PlaylistsMainScreenState extends State<PlaylistsMainScreen> {
  @override
  Widget build(BuildContext context) {
    final List<String> playlistIds =
        PlaylistsData.playlistsData.getValue().keys.toList();
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width ~/ 150,
      children: List.generate(playlistIds.length, (index) {
        final playlist = PlaylistsData.getById(playlistIds[index]);
        return PlaylistCard(playlist);
      }),
    );
  }
}
