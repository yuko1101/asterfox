import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/custom_colors.dart';
import '../data/playlist_data.dart';
import '../main.dart';
import '../music/playlist/playlist.dart';
import '../widget/notifiers_widget.dart';
import '../widget/playlist_card.dart';
import '../widget/screen/scaffold_screen.dart';
import 'asterfox_screen.dart';

class PlaylistsScreen extends ScaffoldScreen {
  PlaylistsScreen({super.key});

  final ValueNotifier<List<AppPlaylist>> playlistsNotifier =
      ValueNotifier(PlaylistsData.getAll());
  final ValueNotifier<Set<AppPlaylist>> selectedPlaylistsNotifier =
      ValueNotifier({});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSizeValueListenableBuilder<Set<AppPlaylist>>(
        valueListenable: selectedPlaylistsNotifier,
        builder: (context, value, child) {
          return AppBar(
            title: Text(l10n.value.playlist),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.value.go_back,
            ),
            actions: value.isEmpty
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
                          playlistsNotifier.value = [...playlistsNotifier.value]
                            ..add(playlist);
                        }
                      },
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.value.delete_playlists),
                            content: Text(l10n.value.delete_playlists_message),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(l10n.value.cancel),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  PlaylistsData.removeMultiple(
                                      value.map((p) => p.id).toList());
                                  playlistsNotifier.value = [
                                    ...playlistsNotifier.value
                                  ]..removeWhere(value.contains);
                                  selectedPlaylistsNotifier.value = {};
                                },
                                child: Text(l10n.value.delete),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
          );
        });
  }

  @override
  Widget body(BuildContext context) {
    return ValueListenableBuilder<List<AppPlaylist>>(
        valueListenable: playlistsNotifier,
        builder: (context, playlists, child) {
          return GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width ~/ 150,
            children: List.generate(playlists.length, (index) {
              return SelectablePlaylistCard(
                  selectedPlaylistsNotifier, playlists[index]);
            }),
          );
        });
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

class SelectablePlaylistCard extends StatelessWidget {
  const SelectablePlaylistCard(this.selectedPlaylistsNotifier, this.playlist,
      {super.key});

  final ValueNotifier<Set<AppPlaylist>> selectedPlaylistsNotifier;
  final AppPlaylist playlist;

  bool get isSelected => selectedPlaylistsNotifier.value.contains(playlist);
  set isSelected(bool value) {
    if (value) {
      selectedPlaylistsNotifier.value = {...selectedPlaylistsNotifier.value}
        ..add(playlist);
    } else {
      selectedPlaylistsNotifier.value = {...selectedPlaylistsNotifier.value}
        ..remove(playlist);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: selectedPlaylistsNotifier,
        builder: (context, value, child) {
          final selectMode = value.isNotEmpty;
          final onTap = selectMode
              ? () => isSelected = !isSelected
              : () {
                  Navigator.of(context).pushNamed(
                    "/playlistInfo",
                    arguments: playlist,
                  );
                };
          final onLongPress = selectMode ? null : () => isSelected = true;

          return isSelected
              ? Card(
                  color: CustomColors.getColor("accent"),
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Stack(
                      children: [
                        PlaylistCard(
                          playlist: playlist,
                          onTap: onTap,
                          onLongPress: onLongPress,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.check_circle,
                            color: CustomColors.getColor("accent"),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : PlaylistCard(
                  playlist: playlist,
                  onTap: onTap,
                  onLongPress: onLongPress,
                );
        });
  }
}
