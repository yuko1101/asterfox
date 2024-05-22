import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../data/playlist_data.dart';
import '../widget/screen/scaffold_screen.dart';
import 'asterfox_screen.dart';

class PlaylistScreen extends ScaffoldScreen {
  const PlaylistScreen({super.key})
      : super(
          appBar: const PlaylistAppBar(),
          body: const PlaylistMainScreen(),
          drawer: const AsterfoxSideMenu(),
        );
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
  const PlaylistMainScreen({super.key});

  @override
  State<PlaylistMainScreen> createState() => _PlaylistMainScreenState();
}

class _PlaylistMainScreenState extends State<PlaylistMainScreen> {
  @override
  Widget build(BuildContext context) {
    final List<String> playlistIds =
        PlaylistsData.playlistsData.getValue().keys.toList();
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width ~/ 200,
      children: List.generate(playlistIds.length, (index) {
        final playlist = PlaylistsData.getById(playlistIds[index]);
        return Card(
          child: Column(
            children: [
              Text(playlist.name),
              Text(playlist.songs.length.toString()),
            ],
          ),
        );
      }),
    );
  }
}
