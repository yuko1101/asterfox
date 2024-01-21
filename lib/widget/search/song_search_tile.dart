import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../system/home_screen_music_manager.dart';
import '../../system/theme/theme.dart';
import '../notifiers_widget.dart';
import 'song_search.dart';

class SongSearchTile extends StatelessWidget {
  SongSearchTile({
    required this.suggestion,
    required this.parent,
    super.key,
  });

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
            localizations: AppLocalizations.of(context)!,
          );
        }
      }
    }

    return DoubleNotifierWidget<bool, bool>(
      notifier1: parent.multiSelectMode,
      notifier2: selectedNotifier,
      builder: (context, multiSelect, isSelected, child) {
        return Visibility(
          visible: !(suggestion.tags.contains(SongTag.word) && multiSelect),
          child: InkWell(
            onTap: onTap,
            onLongPress: multiSelect
                ? null
                : () {
                    parent.multiSelectMode.value = true;

                    selectedNotifier.value = true;
                    updateSelectedList();
                  },
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
                            side: BorderSide(
                              color: icon.color!,
                              width: 2,
                            ),
                            fillColor: MaterialStateProperty.resolveWith(
                              (states) {
                                if (!states.contains(MaterialState.selected)) {
                                  return Colors.transparent;
                                }
                                return icon.color!;
                              },
                            ),
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
          ),
        );
      },
    );
  }
}
