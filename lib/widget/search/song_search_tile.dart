import 'package:flutter/material.dart';

import '../../system/theme/theme.dart';
import '../notifiers_widget.dart';
import 'song_search.dart';
import 'suggestion.dart';

class SongSearchTile<T extends Suggestion> extends StatelessWidget {
  SongSearchTile({
    required this.suggestion,
    required this.parent,
    super.key,
  });

  final T suggestion;
  final SongSearch parent;

  final ValueNotifier<bool> selectedNotifier = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    late Icon icon;

    final suggestion = this.suggestion;

    // TODO: custom colored icons
    if (suggestion is SongSuggestion) {
      if (suggestion.tags.contains(SongTag.installed)) {
        icon = const Icon(Icons.offline_pin_outlined, color: Colors.green);
      } else if (suggestion.tags.contains(SongTag.stored)) {
        icon = const Icon(Icons.star_outline, color: Colors.orange);
      } else {
        icon = const Icon(Icons.library_music_outlined, color: Colors.blue);
      }
    } else {
      icon = const Icon(Icons.tag, color: Colors.grey);
    }

    void updateSelectedList() {
      // update selected list in parent
      if (selectedNotifier.value) {
        parent.selectedTiles.add(this);
      } else {
        parent.selectedTiles.remove(this);
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
        final suggestion = this.suggestion;

        if (suggestion is WordSuggestion) {
          parent.setQuery(suggestion.word);
        } else if (suggestion is SongSuggestion &&
            suggestion.tags.contains(SongTag.youtube)) {
          parent.close(context, Future.wait([suggestion.fetchMusicData()]));
        }
      }
    }

    return DoubleNotifierWidget<bool, bool>(
      notifier1: parent.multiSelectMode,
      notifier2: selectedNotifier,
      builder: (context, multiSelect, isSelected, child) {
        return Visibility(
          visible: !(suggestion is WordSuggestion && multiSelect),
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
                            fillColor: WidgetStateProperty.resolveWith(
                              (states) {
                                if (!states.contains(WidgetState.selected)) {
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
