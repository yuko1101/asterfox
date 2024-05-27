import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/song_history_data.dart';
import '../main.dart';
import '../system/home_screen_music_manager.dart';
import '../system/theme/theme.dart';
import '../widget/screen/scaffold_screen.dart';
import 'asterfox_screen.dart';

class SongHistoryScreen extends ScaffoldScreen {
  const SongHistoryScreen({super.key});

  @override
  PreferredSizeWidget appBar(BuildContext context) => const _AppBar();

  @override
  Widget body(BuildContext context) => const _SongHistory();

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
      title: Text(l10n.value.song_history),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.value.go_back,
      ),
    );
  }
}

class _SongHistory extends StatefulWidget {
  const _SongHistory();

  @override
  State<_SongHistory> createState() => _SongHistoryState();
}

class _SongHistoryState extends State<_SongHistory> {
  @override
  Widget build(BuildContext context) {
    final songs = SongHistoryData.getAll(isTemporary: true).reversed.toList();
    if (songs.isEmpty) {
      return Center(
        child: Text(
          l10n.value.no_song_history,
          style: TextStyle(
            color: Theme.of(context).extraColors.secondary,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          title: Text(song["title"]),
          subtitle: Text(song["author"]),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.value.delete_from_history,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.value.delete_from_history),
                  content: Text(l10n.value.delete_from_history_confirm_message),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.value.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          SongHistoryData.remove(song["audioId"]);
                          Navigator.of(context).pop();
                        });
                      },
                      child: Text(l10n.value.delete),
                    ),
                  ],
                ),
              );
            },
          ),
          onTap: () async {
            final key = const Uuid().v4();
            HomeScreenMusicManager.addSong(
              key: key,
              audioId: song["audioId"],
            );
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
