import 'package:flutter/material.dart';

import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/playlist/playlist.dart';
import '../system/home_screen_music_manager.dart';
import '../widget/playlist_widget.dart';
import '../widget/screen/scaffold_screen.dart';
import 'asterfox_screen.dart';

class PlaylistInfoScreen extends ScaffoldScreen {
  PlaylistInfoScreen(this.playlist, {super.key}) {
    editingSongs = [...playlist.getMusicDataList(true)];
  }

  final AppPlaylist playlist;
  final ValueNotifier<bool> editModeNotifier = ValueNotifier(false);
  late final List<MusicData> editingSongs;

  @override
  PreferredSizeWidget appBar(BuildContext context) {
    return AppBar(
      title: Text("${playlist.name} (${playlist.songs.length})"),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.value.go_back,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            editModeNotifier.value = !editModeNotifier.value;
          },
        ),
        IconButton(
          icon: const Icon(Icons.play_arrow),
          tooltip: l10n.value.play,
          onPressed: () {
            HomeScreenMusicManager.addSongs(
              count: playlist.songs.length,
              musicDataList: playlist.getMusicDataList(false),
            );
            Navigator.of(context).pushNamed("/home");
          },
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) =>
      _PlaylistInfo(editingSongs, editModeNotifier);

  @override
  Widget drawer(BuildContext context) => const AsterfoxSideMenu();

  void resetChanges() {
    editingSongs.clear();
    editingSongs.addAll(playlist.getMusicDataList(true));
  }

  void applyChanges() {
    playlist.songs.clear();
    playlist.songs.addAll(editingSongs.map((s) => s.audioId));
  }
}

class _PlaylistInfo extends StatefulWidget {
  const _PlaylistInfo(this.editingSongs, this.editModeNotifier);

  final List<MusicData> editingSongs;
  final ValueNotifier<bool> editModeNotifier;

  @override
  State<_PlaylistInfo> createState() => _PlaylistInfoState();
}

class _PlaylistInfoState extends State<_PlaylistInfo> {
  @override
  Widget build(BuildContext context) {
    final songs = widget.editingSongs;
    return PlaylistWidgetWithEditMode(
      songs: songs,
      onRemove: (i, _) {
        songs.removeAt(i);
      },
      editModeNotifier: widget.editModeNotifier,
    );
  }
}
