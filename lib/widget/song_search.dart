import 'dart:async';

import 'package:asterfox/config/local_musics_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/youtube_music.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../music/audio_source/youtube_audio.dart';
import '../screen/screens/home_screen.dart';
import '../util/in_app_notification/notification_data.dart';

class SongSearch extends SearchDelegate<String> {
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
          search(context, query);
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
      if (query.isEmpty) {
        loadOfflineSongs();
      } else {
        timer = Timer(const Duration(milliseconds: 500), () {
          loadSuggestions(query);
          print("loading suggestions");
        });
      }

      lastQuery = query;
    }
    return ValueListenableBuilder<List<_Suggestion>>(
      valueListenable: suggestions,
      builder: (_, value, __) => ListView.builder(
        itemBuilder: (context, index) => _SearchTile(value[index], setQuery, () => close(context, "")),
        itemCount: value.length,
      )
    );
  }

  void search(BuildContext context, String text) async {
    close(context, "");
    await addSongBySearch(text);
  }

  void loadSuggestions(String text) async {
    final List<_Suggestion> list = [];
    final List<_Suggestion> sorted = [];

    final List<Video> videos = await searchYouTubeVideo(text);
    final List<String> localIds = LocalMusicsData.getYouTubeIds();

    list.addAll(videos.map((e) => _Suggestion(tags: [_Tag.youtube, localIds.contains(e.id.value) ? _Tag.local : _Tag.remote], name: e.title, value: e.id.value)));

    final List<String> words = await searchWords(text);
    list.addAll(words.map((e) => _Suggestion(tags: [_Tag.word], name: e, value: e)));

    sorted.addAll(list); // TODO: sort suggestions

    suggestions.value = sorted;
    
  }

  void loadOfflineSongs() {
    // TODO: load list of local songs
  }

  void setQuery(newQuery) => query = newQuery;
}

class _SearchTile extends StatelessWidget {
  const _SearchTile(
      this.suggestion,
      this.setQuery,
      this.close,
      {Key? key}) : super(key: key);

  final _Suggestion suggestion;
  final void Function(String) setQuery;
  final VoidCallback close;


  @override
  Widget build(BuildContext context) {
    late IconData iconData;

    // TODO: custom colored icons
    if (suggestion.tags.contains(_Tag.word)) {
      iconData = Icons.search;
    } else if (suggestion.tags.contains(_Tag.local)) {
      iconData = Icons.offline_pin_outlined;
    } else if (suggestion.tags.contains(_Tag.remote)) {
      iconData = Icons.library_music_outlined;
    } else {
      iconData = Icons.question_mark;
    }
    return ListTile(
      leading: Icon(iconData),
      title: Text(suggestion.name),
      onTap: () async {
        if (suggestion.tags.contains(_Tag.word)) {
          setQuery(suggestion.value);
        } else if (suggestion.tags.contains(_Tag.youtube)) {
          close();
          addSongByID(suggestion.value);
        }
      },
    );
  }
}

class _Suggestion {
  _Suggestion({
    required this.tags,
    required this.name,
    required this.value
  });
  final List<_Tag> tags;
  final String name;
  final String value;
}

enum _Tag {
  local,
  remote,
  youtube,
  word
}