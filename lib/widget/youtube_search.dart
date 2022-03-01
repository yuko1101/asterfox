import 'dart:async';

import 'package:asterfox/main.dart';
import 'package:asterfox/music/youtube_music.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeSearch extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        color: Theme.of(context).textTheme.bodyText1?.color,
        tooltip: "クリア",
        onPressed: () {
          query = "";
        }),
      IconButton(
        icon: const Icon(Icons.search),
        color: Theme.of(context).textTheme.bodyText1?.color,
        tooltip: "検索",
      onPressed: () {
          if (query.isEmpty || query == "") return;
          search(context);
        }
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(icon: AnimatedIcons.menu_arrow, progress: transitionAnimation),
      color: Theme.of(context).textTheme.bodyText1?.color,
      tooltip: "戻る",
      onPressed: () {
        close(context, "");
      }
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  ValueNotifier<List<_Suggestion>> suggestions = ValueNotifier<List<_Suggestion>>([]);

  String? lastQuery;

  Timer? timer;

  @override
  Widget buildSuggestions(BuildContext context) {
    if (lastQuery != query) {
      if (timer != null && timer!.isActive) timer!.cancel();
      timer = Timer(const Duration(milliseconds: 500), () {
        loadSuggestions();
        print("loading suggestions");
      });
      lastQuery = query;
    }
    return ValueListenableBuilder<List<_Suggestion>>(
      valueListenable: suggestions,
      builder: (_, value, __) => ListView.builder(
        itemBuilder: (context, index) => _SearchTile(value[index]),
        itemCount: value.length,
      )
    );
  }

  void search(context) {

  }

  void loadSuggestions() {

  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile(
      this.suggestion,
      {Key? key}) : super(key: key);

  final _Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    late IconData iconData;
    if (suggestion.tags.contains(_Tag.local)) {
      iconData = Icons.offline_pin_outlined;
    } else if (suggestion.tags.contains(_Tag.remote)) {
      iconData = Icons.library_music_outlined;
    } else if (suggestion.tags.contains(_Tag.word)) {
      iconData = Icons.search;
    } else {
      iconData = Icons.question_mark;
    }
    return ListTile(
      leading: Icon(iconData),
      title: Text(suggestion.name),
      onTap: () async {
        if (suggestion.tags.contains(_Tag.youtube)) {
          final song = await getYouTubeAudio(VideoId(suggestion.url).value);
          if (song != null) {
            await musicManager.add(song);
          }
        }
      },
    );
  }
}

class _Suggestion {
  _Suggestion({
    required this.tags,
    required this.name,
    required this.url
  });
  final List<_Tag> tags;
  final String name;
  final String url;
}

enum _Tag {
  local,
  remote,
  youtube,
  word
}