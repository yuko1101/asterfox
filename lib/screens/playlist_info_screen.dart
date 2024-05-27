import 'package:flutter/material.dart';

import '../data/playlist_data.dart';
import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/playlist/playlist.dart';
import '../system/home_screen_music_manager.dart';
import '../widget/playlist_widget.dart';
import '../widget/screen/stateful_scaffold_screen.dart';
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
    ...widget.playlist.getMusicDataList(true)
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
                onPressed: () {
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
                onPressed: () {
                  HomeScreenMusicManager.addSongs(
                    count: widget.playlist.songs.length,
                    musicDataList: widget.playlist.getMusicDataList(false),
                  );
                  Navigator.of(context).pushNamed("/home");
                },
              ),
            ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return PlaylistWidgetWithEditMode(
      songs: editingSongs,
      onRemove: (i, _) {
        editingSongs.removeAt(i);
      },
      editMode: editMode,
    );
  }

  @override
  Widget drawer(BuildContext context) => const AsterfoxSideMenu();

  void resetChanges() {
    editingSongs.clear();
    editingSongs.addAll(widget.playlist.getMusicDataList(true));
  }

  void applyChanges() {
    widget.playlist.songs.clear();
    widget.playlist.songs.addAll(editingSongs.map((s) => s.audioId));
    PlaylistsData.addAndSave(widget.playlist);
  }
}
