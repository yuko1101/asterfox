import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/playlist_data.dart';
import '../main.dart';
import '../music/playlist/playlist.dart';
import '../widget/playlist_card.dart';
import '../widget/screen/stateful_scaffold_screen.dart';
import 'asterfox_screen.dart';

class PlaylistsScreen extends StatefulScaffoldScreen {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState
    extends StatefulScaffoldScreenState<PlaylistsScreen> {
  final List<String> playlistIds =
      PlaylistsData.playlistsData.getValue().keys.toList();
  Set<AppPlaylist> selectedPlaylists = {};

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return AppBar(
      title: Text(l10n.value.playlist),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.value.go_back,
      ),
      actions: selectedPlaylists.isEmpty
          ? [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final playlist = await showDialog<AppPlaylist>(
                    context: context,
                    builder: (context) => const PlaylistDialog(),
                  );
                  if (playlist != null) {
                    await PlaylistsData.addAndSave(playlist);
                    setState(() {
                      playlistIds.add(playlist.id);
                    });
                  }
                },
              ),
            ]
          : [],
    );
  }

  @override
  Widget body(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width ~/ 150,
      children: List.generate(playlistIds.length, (index) {
        final playlist = PlaylistsData.getById(playlistIds[index]);
        return PlaylistCard(playlist);
      }),
    );
  }

  @override
  Widget drawer(BuildContext context) => const AsterfoxSideMenu();
}

class PlaylistDialog extends StatelessWidget {
  const PlaylistDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    return AlertDialog(
      title: Text(l10n.value.create_playlist),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.value.playlist_name,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.value.cancel),
        ),
        TextButton(
          onPressed: () {
            final playlist = AppPlaylist(
              id: const Uuid().v4(),
              name: controller.text,
              songs: [],
            );
            Navigator.of(context).pop(playlist);
          },
          child: Text(l10n.value.create),
        ),
      ],
    );
  }
}
