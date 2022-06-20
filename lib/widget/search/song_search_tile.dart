import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../system/home_screen_music_manager.dart';
import '../../system/theme/theme.dart';
import 'song_search.dart';

class SongSearchTile extends StatelessWidget {
  const SongSearchTile({
    required this.suggestion,
    required this.setQuery,
    required this.close,
    Key? key,
  }) : super(key: key);

  final SongSuggestion suggestion;
  final void Function(String) setQuery;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    late Icon icon;

    // TODO: custom colored icons
    if (suggestion.tags.contains(SongTag.word)) {
      icon = const Icon(Icons.tag, color: Colors.grey);
    } else if (suggestion.tags.contains(SongTag.local)) {
      icon = const Icon(Icons.offline_pin_outlined, color: Colors.green);
    } else if (suggestion.tags.contains(SongTag.remote)) {
      icon = const Icon(Icons.library_music_outlined, color: Colors.blue);
    } else {
      icon = const Icon(Icons.question_mark);
    }
    return InkWell(
      onTap: () {
        if (suggestion.tags.contains(SongTag.word)) {
          setQuery(suggestion.audioId);
        } else if (suggestion.tags.contains(SongTag.youtube)) {
          close();
          HomeScreenMusicManager.addSong(
            key: const Uuid().v4(),
            youtubeId: suggestion.audioId,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 10, right: 10),
              width: 40,
              height: 40,
              child: icon,
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
            )
          ],
        ),
      ),
    );
  }
}
