import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/widget/notifiers_widget.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../system/home_screen_music_manager.dart';
import '../../system/theme/theme.dart';
import 'song_search.dart';

class SongSearchTile extends StatelessWidget {
  SongSearchTile({
    required this.suggestion,
    required this.parent,
    Key? key,
  }) : super(key: key);

  final SongSuggestion suggestion;
  final SongSearch parent;

  final ValueNotifier<bool> selectedNotifier = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    late Icon icon;

    // TODO: custom colored icons
    if (suggestion.tags.contains(SongTag.word)) {
      icon = const Icon(Icons.tag, color: Colors.grey);
    } else if (suggestion.tags.contains(SongTag.installed)) {
      icon = const Icon(Icons.offline_pin_outlined, color: Colors.green);
    } else if (suggestion.tags.contains(SongTag.stored)) {
      icon = const Icon(Icons.star_outline, color: Colors.orange);
    } else {
      icon = const Icon(Icons.library_music_outlined, color: Colors.blue);
    }

    void updateSelectedList() {
      // update selected list in parent
      if (selectedNotifier.value) {
        if (!parent.selectedTiles.contains(this)) {
          parent.selectedTiles.add(this);
        }
      } else {
        if (parent.selectedTiles.contains(this)) {
          parent.selectedTiles.remove(this);
        }
      }
    }

    Future<void> onTap() async {
      if (parent.multiSelectMode.value) {
        selectedNotifier.value = !selectedNotifier.value;
        updateSelectedList();

        // if there are no selected songs, disable multi-select mode.
        if (parent.selectedTiles.isEmpty) {
          parent.multiSelectMode.value = false;
        }
      } else {
        if (suggestion.tags.contains(SongTag.word)) {
          parent.setQuery(suggestion.word!);
        } else if (suggestion.tags.contains(SongTag.youtube)) {
          parent.close(context, "");
          await HomeScreenMusicManager.addSong(
            key: const Uuid().v4(),
            musicData: suggestion.musicData,
            mediaUrl: suggestion.mediaUrl,
          );
        }
      }
    }

    return InkWell(
      onTap: onTap,
      onLongPress: () {
        if (parent.multiSelectMode.value) return;
        parent.multiSelectMode.value = true;

        selectedNotifier.value = true;
        updateSelectedList();
      },
      child: DoubleNotifierWidget<bool, bool>(
        notifier1: parent.multiSelectMode,
        notifier2: selectedNotifier,
        builder: (context, multiSelect, isSelected, child) {
          return Visibility(
            visible: !(suggestion.tags.contains(SongTag.word) && multiSelect),
            child: Container(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 10),
                    width: 40,
                    height: 40,
                    child: !multiSelect
                        ? icon
                        : Checkbox(
                            value: isSelected,
                            onChanged: (value) => onTap(),
                            fillColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                return icon.color!.withOpacity(0.32);
                              }
                              return icon.color!;
                            }),
                          ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          suggestion.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).extraColors.primary,
                          ),
                        ),
                        if (suggestion.subtitle != null)
                          Text(
                            suggestion.subtitle!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).extraColors.secondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
