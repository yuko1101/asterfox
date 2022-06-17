import 'package:asterfox/widget/search/song_search.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../system/home_screen_music_manager.dart';

class SongSearchTile extends StatelessWidget {
  const SongSearchTile(
      this.suggestion,
      this.setQuery,
      this.close,
      {Key? key}) : super(key: key);

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
    return ListTile(
      leading: icon,
      title: Text(suggestion.name),
      onTap: () async {
        if (suggestion.tags.contains(SongTag.word)) {
          setQuery(suggestion.audioId);
        } else if (suggestion.tags.contains(SongTag.youtube)) {
          close();
          HomeScreenMusicManager.addSong(key: const Uuid().v4(), youtubeId: suggestion.audioId);
        }
      },
    );
  }
}