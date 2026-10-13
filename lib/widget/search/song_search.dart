import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide MusicData;

import '../../data/custom_colors.dart';
import '../../data/local_musics_data.dart';
import '../../data/playlist_data.dart';
import '../../main.dart';
import '../../music/music_data/music_data.dart';
import '../../music/music_data/youtube_music_data.dart';
import '../../music/utils/music_data_utils.dart';
import '../../music/utils/youtube_music_utils.dart';
import '../../system/theme/theme.dart';
import '../../utils/network_utils.dart';
import 'search_options.dart';
import 'search_options_panel.dart';
import 'search_scope_button.dart';
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
  /// Whether the results come from the songs stored on this device rather than
  /// from YouTube. Searching the library is the default, and the switch in the
  /// options panel turns it off.
  bool offlineSearch = true;

  /// How the stored songs are grouped, filtered and ordered.
  SearchOptions searchOptions = const SearchOptions();

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
      // Which of the two scopes is searched is switched from here, in one
      // press, rather than from inside the options.
      SearchScopeButton(
        offline: offlineSearch,
        onChanged: (offline) {
          offlineSearch = offline;
          lastQuery = null;
          searchResults();
        },
      ),
      IconButton(
        icon: const Icon(Icons.tune),
        color: Theme.of(context).extraColors.primary,
        tooltip: l10n.value.search_options,
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
                  child: SearchOptionsPanel(
                    options: searchOptions,
                    offline: offlineSearch,
                    onOptionsChanged: (options) {
                      searchOptions = options;
                      // The results are already on screen, so they are rebuilt
                      // with the new selection rather than waiting for the
                      // query to change.
                      loadOfflineSongs(query);
                    },
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
            songs = MusicDataUtils.searchList(query);
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
      songs = MusicDataUtils.searchList(query);
    }
    close(context, songs);
  }

  final ValueNotifier<List<SongSearchTile>> suggestionTiles = ValueNotifier([]);

  /// The tiles of the offline results, under the headings the chosen grouping
  /// asks for. With no grouping there is a single group with no title.
  final ValueNotifier<List<SuggestionGroup>> songGroups = ValueNotifier([]);
  final ValueNotifier<List<SongSearchTile>> otherSelectedTilesNotifier =
      ValueNotifier([]);

  String? lastQuery;

  Timer? timer;
  int searchedAt = 0;
  final ValueNotifier<bool> loading = ValueNotifier(false);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (lastQuery != query) {
      searchResults();
      lastQuery = query;
    }
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
            child: ValueListenableBuilder<List<SuggestionGroup>>(
              valueListenable: songGroups,
              builder: (_, groups, __) => ListView.builder(
                shrinkWrap: false,
                itemBuilder: (context, index) =>
                    _buildGroup(context, groups[index], index),
                itemCount: groups.length,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// One heading and the songs under it, at [index] in the list.
  ///
  /// A heading with no title is the whole list when no grouping is chosen, so
  /// it is shown as plain rows rather than a collapsed section.
  Widget _buildGroup(BuildContext context, SuggestionGroup group, int index) {
    final tiles = group.suggestions.map(_getSongSearchTile).toList();
    if (group.title.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: tiles,
      );
    }
    return ExpansionTile(
      // Without a key the state of a heading is lost as soon as it is scrolled
      // out of view, and it comes back open: the list is a ListView, which
      // builds only what is on screen. The key is what lets the tile save its
      // open-or-closed state and restore it.
      //
      // The position is part of the key because two playlists can have the
      // same name, and they are not the same heading.
      key: PageStorageKey<String>('search-group-$index-${group.title}'),
      initiallyExpanded: true,
      title: Text(
        group.title,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).extraColors.primary,
        ),
      ),
      children: tiles,
    );
  }

  /// Runs the search the current query and options ask for.
  ///
  /// The stored songs are the default: they are what the user is most likely
  /// looking for, and they need no network. YouTube is searched when the
  /// offline search has been turned off, or when there is no network to reach
  /// it with and there is a query to look up.
  void searchResults() {
    searchedAt = DateTime.now().millisecondsSinceEpoch;
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }

    if (offlineSearch || !NetworkUtils.networkAccessible()) {
      loadOfflineSongs(query);
      return;
    }
    if (query.isEmpty) {
      loadOfflineSongs(query);
      return;
    }
    final time = DateTime.now().millisecondsSinceEpoch;
    timer = Timer(const Duration(milliseconds: 500), () {
      loadSuggestions(query, time: time);
    });
  }

  void loadSuggestions(String text, {int? time}) async {
    loading.value = true;
    final yt = YoutubeExplode();
    final fetched = await Future.wait([
      YouTubeMusicUtils.searchYouTubeVideo(text, yt),
      YouTubeMusicUtils.searchWords(text, yt),
    ]);
    yt.close();
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
    // The tiles of the previous search are dropped, so a song that changed
    // state (it was downloaded, say) is shown with its state now rather than
    // the one it had when the tile was made.
    _tiles.clear();
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
      filterSortingList: [
        RelatedFilter(text),
        // The order these run in decides what is narrowed first: the
        // relevance of the query is settled before the list is narrowed or
        // reordered, so a chosen sort survives the text filter.
        if (searchOptions.state == SearchStateFilter.installed)
          InstalledFilter(),
        if (searchOptions.lyrics != SearchLyricsFilter.all)
          LyricsFilter(searchOptions.lyrics),
        switch (searchOptions.sort) {
          SearchSort.relevance => RelevanceSorting(text),
          SearchSort.addedNewest => AddedSorting(newestFirst: true),
          SearchSort.addedOldest => AddedSorting(newestFirst: false),
        },
      ],
    );
    suggestionTiles.value = result.map((s) => _getSongSearchTile(s)).toList();
    songGroups.value = groupSuggestions(
      result,
      searchOptions.grouping,
      noPlaylistTitle: l10n.value.no_playlist,
      playlists: [
        for (final playlist in PlaylistsData.getAll())
          PlaylistMembership(
            name: playlist.name,
            audioIds: playlist.songs.toSet(),
          ),
      ],
    );
    // suggestionTiles.valueに含まれていない、選択されたSongSearchTile
    otherSelectedTilesNotifier.value = selectedTiles
        .where((s1) => !suggestionTiles.value
            .any((s2) => s1.suggestion.isSameSuggestion(s2.suggestion)))
        .toList();
    loading.value = false;
  }

  /// The tiles of the results, so that the same suggestion is shown as the
  /// same tile wherever it appears.
  final Map<String, SongSearchTile> _tiles = {};

  SongSearchTile _getSongSearchTile(Suggestion suggestion) {
    final matched = selectedTiles
        .firstWhereOrNull((s) => suggestion.isSameSuggestion(s.suggestion));
    if (matched != null) {
      return matched;
    }
    // A song listed under two playlists is drawn once per playlist, and the
    // selection is held by the tile, so both have to be the same object.
    return _tiles.putIfAbsent(
      _suggestionKey(suggestion),
      () => SongSearchTile(suggestion: suggestion, parent: this),
    );
  }

  /// What makes two suggestions the same one to the user.
  String _suggestionKey(Suggestion suggestion) {
    if (suggestion is SongSuggestion) {
      return suggestion.musicData?.audioId ?? suggestion.mediaUrl ?? "";
    }
    if (suggestion is WordSuggestion) return suggestion.word;
    return suggestion.title;
  }

  /// The tile that shows [suggestion] in the results.
  ///
  /// A song that is listed under more than one playlist goes through here once
  /// per group, and comes back as the same tile each time: selecting it in one
  /// group has to be the same selection as in the other, or it ends up in the
  /// queue twice.
  SongSearchTile tileFor(Suggestion suggestion) => _getSongSearchTile(suggestion);

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
