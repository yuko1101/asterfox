import 'dart:async';

import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/audio_source/youtube_music_data.dart';
import 'package:asterfox/system/home_screen_music_manager.dart';
import 'package:asterfox/utils/youtube_music_utils.dart';
import 'package:asterfox/widget/search/song_search_tile.dart';
import 'package:asterfox/widget/search/sort_and_filter.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:easy_app/utils/network_utils.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SongSearch extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        color: Theme.of(context).textTheme.bodyText1?.color,
        tooltip: Language.getText("clear"),
        onPressed: () {
          query = "";
        },),
      IconButton(
        icon: const Icon(Icons.search),
        color: Theme.of(context).textTheme.bodyText1?.color,
        tooltip: Language.getText("search"),
        onPressed: () {
            if (query.isEmpty || query == "") return;
            search(context, query);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(icon: AnimatedIcons.menu_arrow, progress: transitionAnimation),
      color: Theme.of(context).textTheme.bodyText1?.color,
      tooltip: Language.getText("go_back"),
      onPressed: () {
        close(context, "");
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  ValueNotifier<List<SongSuggestion>> suggestions = ValueNotifier<List<SongSuggestion>>([]);

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
    return ValueListenableBuilder<List<SongSuggestion>>(
      valueListenable: suggestions,
      builder: (_, value, __) => ListView.builder(
        itemBuilder: (context, index) => SongSearchTile(value[index], setQuery, () => close(context, "")),
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

    final videoSuggestions = videos.map((e) => SongSuggestion(tags: [SongTag.youtube, localIds.contains(e.id.value) ? SongTag.local : SongTag.remote], name: e.title, audioId: e.id.value, keywords: e.keywords)).toList();

    final List<String> words = await YouTubeMusicUtils.searchWords(text);
    final wordsSuggestions = words.map((e) => SongSuggestion(tags: [SongTag.word], name: e, audioId: e, keywords: [])).toList();

    final videoResult = filterAndSort(videoSuggestions);
    final wordResult = filterAndSort(wordsSuggestions);

    final result = [...videoResult, ...wordResult];

    if (time == null || (time >= searchedAt)) {
      suggestions.value = result;
    }
    
  }

  void loadOfflineSongs(String text) {
    print("loading offline songs");
    final List<SongSuggestion> list = [];

    final List<MusicData> locals = LocalMusicsData.getAll(isTemporary: true);
    list.addAll(locals.map((e) {
      final List<SongTag> tags = [SongTag.local];
      if (e is YouTubeMusicData) tags.add(SongTag.youtube);
      return SongSuggestion(tags: tags, name: e.title, audioId: e is YouTubeMusicData ? e.id : e.url, keywords: e.keywords);
    }));

    final List<SongSuggestion> result = filterAndSort(list, filterSortingList: [RelatedFilter(text), RelevanceSorting(text)]);
    suggestions.value = result;

  }

  void setQuery(newQuery) => query = newQuery;
}

class SongSuggestion {
  SongSuggestion({
    required this.tags,
    required this.name,
    required this.audioId,
    required this.keywords
  });
  final List<SongTag> tags;
  final String name;
  final String audioId;
  final List<String> keywords;
}

enum SongTag {
  local,
  remote,
  youtube,
  word
}