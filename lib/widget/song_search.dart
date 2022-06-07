import 'dart:async';

import 'package:asterfox/config/local_musics_data.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/audio_source/youtube_music_data.dart';
import 'package:asterfox/system/home_screen_music_manager.dart';
import 'package:asterfox/utils/youtube_music_utils.dart';
import 'package:easy_app/utils/network_utils.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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
  int searchedAt = 0;

  @override
  Widget buildSuggestions(BuildContext context) {
    if (lastQuery != query) {
      searchedAt = DateTime.now().millisecondsSinceEpoch;
      if (timer != null && timer!.isActive) {
        print("timer.cancel");
        timer!.cancel();

      }

      if (NetworkUtils.networkAccessible()) {
        if (query.isEmpty) {
          loadOfflineSongs(query);
        } else {
          final time = DateTime.now().millisecondsSinceEpoch;
          timer = Timer(const Duration(milliseconds: 500), () {
            loadSuggestions(query, time: time);
            print("loading suggestions");
          });
        }
      } else {
        loadOfflineSongs(query);
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
    await HomeScreenMusicManager.addSongBySearch(text);
  }

  void loadSuggestions(String text, {int? time}) async {
    final List<Video> videos = await YouTubeMusicUtils.searchYouTubeVideo(text);
    final List<String> localIds = LocalMusicsData.getYouTubeIds();

    final videoSuggestions = videos.map((e) => _Suggestion(tags: [_Tag.youtube, localIds.contains(e.id.value) ? _Tag.local : _Tag.remote], name: e.title, value: e.id.value, keywords: e.keywords)).toList();

    final List<String> words = await YouTubeMusicUtils.searchWords(text);
    final wordsSuggestions = words.map((e) => _Suggestion(tags: [_Tag.word], name: e, value: e, keywords: [])).toList();

    final videoResult = filterAndSort(videoSuggestions);
    final wordResult = filterAndSort(wordsSuggestions);

    final result = [...videoResult, ...wordResult];

    // ignore the warning
    if (time == null || (time != null && time >= searchedAt)) {
      suggestions.value = result;
    }
    
  }

  void loadOfflineSongs(String text) {
    print("loading offline songs");
    final List<_Suggestion> list = [];

    final List<MusicData> locals = LocalMusicsData.getAll();
    list.addAll(locals.map((e) {
      final List<_Tag> tags = [_Tag.local];
      if (e is YouTubeMusicData) tags.add(_Tag.youtube);
      return _Suggestion(tags: tags, name: e.title, value: e is YouTubeMusicData ? e.id : e.url, keywords: e.keywords);
    }));

    final List<_Suggestion> result = filterAndSort(list, filterSortingList: [_RelatedFilter(text), _RelevanceSorting(text)]);
    suggestions.value = result;

  }

  List<_Suggestion> filterAndSort(List<_Suggestion> list, {List<_FilterSorting>? filterSortingList}) {
    if (filterSortingList == null) return list;
    List<_Suggestion> result = list;
    for (final filterSorting in filterSortingList) {
      result = filterSorting.apply(result);
    }
    return result;
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
    late Icon icon;

    // TODO: custom colored icons
    if (suggestion.tags.contains(_Tag.word)) {
      icon = const Icon(Icons.tag, color: Colors.grey);
    } else if (suggestion.tags.contains(_Tag.local)) {
      icon = const Icon(Icons.offline_pin_outlined, color: Colors.green);
    } else if (suggestion.tags.contains(_Tag.remote)) {
      icon = const Icon(Icons.library_music_outlined, color: Colors.blue);
    } else {
      icon = const Icon(Icons.question_mark);
    }
    return ListTile(
      leading: icon,
      title: Text(suggestion.name),
      onTap: () async {
        if (suggestion.tags.contains(_Tag.word)) {
          setQuery(suggestion.value);
        } else if (suggestion.tags.contains(_Tag.youtube)) {
          close();
          HomeScreenMusicManager.addSongByID(suggestion.value);
        }
      },
    );
  }
}

class _Suggestion {
  _Suggestion({
    required this.tags,
    required this.name,
    required this.value,
    required this.keywords
  });
  final List<_Tag> tags;
  final String name;
  final String value;
  final List<String> keywords;
}

enum _Tag {
  local,
  remote,
  youtube,
  word
}

class _FilterSorting {
  List<_Suggestion> apply(List<_Suggestion> list) {
    return list;
  }
}

class _YouTubeFilter extends _FilterSorting {
  @override
  List<_Suggestion> apply(List<_Suggestion> list) {
    return list.where((element) => element.tags.contains(_Tag.youtube)).toList();
  }
}

class _LocalFilter extends _FilterSorting {
  @override
  List<_Suggestion> apply(List<_Suggestion> list) {
    return list.where((element) => element.tags.contains(_Tag.local)).toList();
  }
}

class _RelatedFilter extends _FilterSorting {
  _RelatedFilter(this.query);
  final String query;
  @override
  List<_Suggestion> apply(List<_Suggestion> list) {
    if (query.isEmpty) return list;
    return list.where((element) => _getScore(element, query) > 0).toList();
  }
}

class _RelevanceSorting extends _FilterSorting {
  _RelevanceSorting(this.query);
  final String query;
  @override
  List<_Suggestion> apply(List<_Suggestion> list) {
    if (query.isEmpty) return list;
    list.sort((a, b) {
      final aScore = _getScore(a, query);
      final bScore = _getScore(b, query);
      return bScore.compareTo(aScore);
    });
    return list;
  }
}

int _getScore(_Suggestion suggestion, String query) {
  int score = 0;
  if (suggestion.name.toLowerCase().contains(query.toLowerCase())) score += 1;
  if (suggestion.keywords.any((e) => e.toLowerCase().contains(query.toLowerCase()))) score += 1;
  return score;
}