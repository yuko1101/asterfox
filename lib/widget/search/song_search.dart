import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/custom_colors.dart';
import '../../data/local_musics_data.dart';
import '../../main.dart';
import '../../music/music_data/music_data.dart';
import '../../music/music_data/youtube_music_data.dart';
import '../../music/utils/music_data_utils.dart';
import '../../music/utils/youtube_music_utils.dart';
import '../../system/theme/theme.dart';
import '../../utils/network_utils.dart';
import '../option_widgets/option_switch.dart';
import 'song_search_tile.dart';
import 'sort_and_filter.dart';
import 'suggestion.dart';

class SongSearch
    extends SearchDelegate<Future<List<MusicData<CachingDisabled>>>> {
  SongSearch({this.animationController});
  final AnimationController? animationController;

  final ValueNotifier<bool> multiSelectMode = ValueNotifier(false);

  final Set<SongSearchTile> selectedTiles = {};

  // search options
  bool forceOfflineSearch = false;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      ValueListenableBuilder<bool>(
        valueListenable: loading,
        builder: (_, isLoading, __) => Visibility(
          visible: isLoading,
          child: Container(
            height: 25,
            width: 25,
            margin: const EdgeInsets.only(right: 10),
            child: FittedBox(
              fit: BoxFit.contain,
              child: CircularProgressIndicator(
                color: CustomColors.getColor("accent"),
              ),
            ),
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.clear),
        color: Theme.of(context).extraColors.primary,
        tooltip: l10n.value.clear,
        onPressed: () {
          query = "";
        },
      ),
      IconButton(
        icon: const Icon(Icons.tune),
        color: Theme.of(context).extraColors.primary,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
              child: Material(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                color:
                    Theme.of(context).extraColors.themeColor.withOpacity(0.9),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: OptionSwitch(
                          title: Text(l10n.value.offline_search),
                          value: forceOfflineSearch,
                          onChanged: (from, to) {
                            forceOfflineSearch = to;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.search),
        color: Theme.of(context).extraColors.primary,
        tooltip: l10n.value.search,
        onPressed: () {
          late final Future<List<MusicData<CachingDisabled>>> songs;
          if (multiSelectMode.value) {
            songs = Future.wait(selectedTiles
                .where((tile) => tile.suggestion is SongSuggestion)
                .map((tile) =>
                    (tile.suggestion as SongSuggestion).fetchMusicData()));
          } else {
            if (query.isEmpty || query == "") return;
            songs = Future.wait([MusicDataUtils.search(query)]);
          }
          close(context, songs);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: animationController ?? transitionAnimation,
      ),
      color: Theme.of(context).extraColors.primary,
      tooltip: l10n.value.go_back,
      onPressed: () {
        close(context, Future.value([]));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  void showResults(BuildContext context) {
    late final Future<List<MusicData<CachingDisabled>>> songs;
    if (multiSelectMode.value) {
      songs = Future.wait(selectedTiles
          .where((tile) => tile.suggestion is SongSuggestion)
          .map((tile) => (tile.suggestion as SongSuggestion).fetchMusicData()));
    } else {
      if (query.isEmpty || query == "") return close(context, Future.value([]));
      songs = Future.wait([MusicDataUtils.search(query)]);
    }
    close(context, songs);
  }

  final ValueNotifier<List<SongSearchTile>> suggestionTiles = ValueNotifier([]);
  final ValueNotifier<List<SongSearchTile>> otherSelectedTilesNotifier =
      ValueNotifier([]);

  String? lastQuery;

  Timer? timer;
  int searchedAt = 0;
  final ValueNotifier<bool> loading = ValueNotifier(false);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (lastQuery != query) {
      searchedAt = DateTime.now().millisecondsSinceEpoch;
      if (timer != null && timer!.isActive) {
        print("timer.cancel");
        timer!.cancel();
      }

      if (NetworkUtils.networkAccessible() && !forceOfflineSearch) {
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
    print(MediaQuery.of(context).viewPadding.bottom);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<List<SongSearchTile>>(
          valueListenable: otherSelectedTilesNotifier,
          builder: (context, value, child) => Visibility(
            visible: value.isNotEmpty,
            child: ExpansionTile(
              title: Text(
                "${l10n.value.selected_songs} (${value.length})",
              ),
              children: [
                Material(
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6),
                    child: ListView(
                      children: value,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        Expanded(
          child: Material(
            clipBehavior: Clip.antiAlias,
            child: ValueListenableBuilder<List<SongSearchTile>>(
              valueListenable: suggestionTiles,
              builder: (_, value, __) => ListView.builder(
                shrinkWrap: false,
                itemBuilder: (context, index) {
                  return value[index];
                },
                itemCount: value.length,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void loadSuggestions(String text, {int? time}) async {
    loading.value = true;
    final fetched = await Future.wait([
      YouTubeMusicUtils.searchYouTubeVideo(text),
      YouTubeMusicUtils.searchWords(text),
    ]);
    final List<Video> videos = fetched[0].map((e) => e as Video).toList();
    final List<String> words = fetched[1].map((e) => e as String).toList();

    final videoSuggestions = videos.map((e) {
      final List<SongTag> tags = [SongTag.youtube];
      if (LocalMusicsData.isStored(audioId: e.id.value)) {
        tags.add(SongTag.stored);
        if (LocalMusicsData.isInstalled(audioId: e.id.value)) {
          tags.add(SongTag.installed);
        }
      }

      return SongSuggestion(
        tags: tags,
        title: e.title,
        subtitle: e.author,
        mediaUrl: e.url,
        keywords: e.keywords,
      );
    }).toList();

    final wordsSuggestions = words
        .map((e) => WordSuggestion(title: e, word: e, keywords: []))
        .toList();

    final videoResult = filterAndSort(
      list: videoSuggestions,
      filterSortingList: [],
    );
    final wordResult = filterAndSort(
      list: wordsSuggestions,
      filterSortingList: [],
    );

    final result = [...videoResult, ...wordResult];

    if (time == null || (time >= searchedAt)) {
      suggestionTiles.value = result.map((s) => _getSongSearchTile(s)).toList();
      // suggestionTiles.valueに含まれていない、選択されたSongSearchTile
      otherSelectedTilesNotifier.value = selectedTiles
          .where((s1) => !suggestionTiles.value
              .any((s2) => s1.suggestion.isSameSuggestion(s2.suggestion)))
          .toList();
      loading.value = false;
    }
  }

  Future<void> loadOfflineSongs(String text) async {
    loading.value = true;
    print("loading offline songs");
    final List<SongSuggestion> list = [];

    final List<MusicData<CachingDisabled>> storedSongs =
        LocalMusicsData.getAll(caching: CachingDisabled());
    list.addAll(storedSongs.map((e) {
      final List<SongTag> tags = [SongTag.stored];
      if (e.isInstalled) tags.add(SongTag.installed);
      if (e is YouTubeMusicData) tags.add(SongTag.youtube);
      return SongSuggestion(
        tags: tags,
        title: e.title,
        subtitle: e.author,
        musicData: e,
        keywords: e.keywords,
        lyrics: e.lyrics,
      );
    }));

    final List<Suggestion> result = filterAndSort(
      list: list,
      filterSortingList: [RelatedFilter(text), RelevanceSorting(text)],
    );
    suggestionTiles.value = result.map((s) => _getSongSearchTile(s)).toList();
    // suggestionTiles.valueに含まれていない、選択されたSongSearchTile
    otherSelectedTilesNotifier.value = selectedTiles
        .where((s1) => !suggestionTiles.value
            .any((s2) => s1.suggestion.isSameSuggestion(s2.suggestion)))
        .toList();
    loading.value = false;
  }

  SongSearchTile _getSongSearchTile(Suggestion suggestion) {
    final matched = selectedTiles
        .firstWhereOrNull((s) => suggestion.isSameSuggestion(s.suggestion));
    if (matched != null) {
      return matched;
    } else {
      return SongSearchTile(suggestion: suggestion, parent: this);
    }
  }

  void setQuery(newQuery) => query = newQuery;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = super.appBarTheme(context);
    final fixedAppBarTheme = theme.appBarTheme.copyWith(
      systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
    );

    return theme.copyWith(
      appBarTheme: fixedAppBarTheme,
    );
  }
}
