import 'package:flutter/material.dart';

import '../data/local_musics_data.dart';
import '../data/playlist_data.dart';
import '../main.dart';
import '../music/music_data/music_data.dart';
import '../music/playlist/playlist.dart';
import '../system/home_screen_music_manager.dart';
import '../widget/playlist_widget.dart';
import '../widget/screen/stateful_scaffold_screen.dart';
import '../widget/search/song_search.dart';
import 'asterfox_screen.dart';

class PlaylistInfoScreen extends StatefulScaffoldScreen {
  const PlaylistInfoScreen(this.playlist, {super.key});

  final AppPlaylist playlist;

  @override
  State<PlaylistInfoScreen> createState() => _PlaylistInfoScreenState();
}

class _PlaylistInfoScreenState
    extends StatefulScaffoldScreenState<PlaylistInfoScreen> {
  bool editMode = false;
  late final List<MusicData> editingSongs = [
    ...widget.playlist.getMusicDataListWithoutCaching()
  ];

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return AppBar(
      title: Text("${widget.playlist.name} (${widget.playlist.songs.length})"),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.value.go_back,
      ),
      actions: editMode
          ? [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final result = await showSearch(
                    context: context,
                    delegate: SongSearch(),
                  );
                  final songs = await result;
                  if (songs != null && songs.isNotEmpty) {
                    setState(() {
                      editingSongs.addAll(songs);
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    editMode = false;
                    resetChanges();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  final notStoredSongs =
                      editingSongs.where((s) => !s.isStored).toList();
                  bool cancel = false;
                  if (notStoredSongs.isNotEmpty &&
                      !await showDialog(
                        context: context,
                        builder: (context) => StoreSongsDialog(notStoredSongs),
                      )) {
                    cancel = true;
                  }
                  if (cancel) return;
                  setState(() {
                    editMode = false;
                    applyChanges();
                  });
                },
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    editMode = true;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: l10n.value.play,
                onPressed: widget.playlist.songs.isNotEmpty
                    ? () {
                        HomeScreenMusicManager.addSongs(
                          count: widget.playlist.songs.length,
                          musicDataList:
                              widget.playlist.getMusicDataListWithoutCaching(),
                        );
                        Navigator.of(context).pushNamed("/home");
                      }
                    : null,
              ),
            ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return PlaylistWidgetWithEditMode(
      songs: editingSongs,
      onRemove: (i, song, direction) {
        editingSongs.removeAt(i);
      },
      editMode: editMode,
    );
  }

  @override
  Widget drawer(BuildContext context) => const AsterfoxSideMenu();

  void resetChanges() {
    editingSongs.clear();
    editingSongs.addAll(widget.playlist.getMusicDataListWithoutCaching());
  }

  void applyChanges() {
    widget.playlist.songs.clear();
    widget.playlist.songs.addAll(editingSongs.map((s) => s.audioId));
    PlaylistsData.addAndSave(widget.playlist);
  }
}

class StoreSongsDialog extends StatelessWidget {
  const StoreSongsDialog(this.songs, {super.key});

  final List<MusicData> songs;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.value.store_songs),
      content: Text(l10n.value.store_songs_explanation),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.value.cancel),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
            await LocalMusicsData.storeMultiple(songs);
          },
          child: Text(l10n.value.ok),
        ),
      ],
    );
  }
}
