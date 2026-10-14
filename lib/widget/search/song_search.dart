import 'dart:async';
import 'dart:math';

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
import 'song_search_skeleton.dart';
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
  /// How the stored songs are grouped, filtered and ordered.
  SearchOptions searchOptions = const SearchOptions();

  /// Where the randomness of the shuffled order comes from.
  ///
  /// Replaced in tests, so a shuffle can be checked without depending on how
  /// the generator picks.
  Random Function() random = Random.new;

  /// How long typing has to stop for before YouTube is asked.
  ///
  /// Searching YouTube costs a request, so it is not done for every keystroke,
  /// while the stored songs are shown as they are typed.
  Duration searchDelay = const Duration(milliseconds: 500);

  /// Fetches the YouTube suggestions for a query.
  ///
  /// The whole of the YouTube side of the search is behind this, so a test can
  /// drive it without a network.
  Future<List<Suggestion>> Function(String query) youtubeSearch =
      _searchYouTube;

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

  /// The tiles of the YouTube results, under the stored songs. Empty while
  /// nothing has come back yet.
  final ValueNotifier<List<SongSearchTile>> youtubeTiles = ValueNotifier([]);

  /// Whether the YouTube results are on their way, so a placeholder is shown
  /// under the stored songs.
  final ValueNotifier<bool> youtubeLoading = ValueNotifier(false);

  String? lastQuery;

  Timer? timer;

  /// Counts the searches, so the results of an older one can be told apart from
  /// the results of the one that replaced it.
  int searchId = 0;

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
            child: ListView(
              children: [
                ValueListenableBuilder<List<SuggestionGroup>>(
                  valueListenable: songGroups,
                  builder: (context, groups, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < groups.length; index++)
                        _buildGroup(context, groups[index], index),
                    ],
                  ),
                ),
                // What YouTube found for the query, under the stored songs. A
                // placeholder stands in for them until they arrive.
                ValueListenableBuilder<List<SongSearchTile>>(
                  valueListenable: youtubeTiles,
                  builder: (context, tiles, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: tiles,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: youtubeLoading,
                  builder: (context, isLoading, __) => Visibility(
                    visible: isLoading,
                    child: const _YoutubeResultSkeletons(),
                  ),
                ),
              ],
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

  /// Runs the search the current query asks for.
  ///
  /// The stored songs are answered at once, since they need no network, and the
  /// YouTube results follow underneath them once the typing has stopped. There
  /// is no border between the two: YouTube is only worth asking when there is a
  /// query, and only when there is a network.
  void searchResults() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }

    loadOfflineSongs(query);

    final wanted = query;
    final time = ++searchId;
    final noQuery = wanted.isEmpty;
    final offline = !NetworkUtils.networkAccessible();
    if (noQuery || offline) {
      // Nothing from YouTube is coming, so no placeholder is left behind.
      youtubeTiles.value = [];
      youtubeLoading.value = false;
      return;
    }

    // A placeholder under the stored songs while the request is on its way.
    youtubeTiles.value = [];
    youtubeLoading.value = true;
    timer = Timer(searchDelay, () {
      loadYoutubeResults(wanted, time: time);
    });
  }

  /// Adds the YouTube results under the stored songs.
  ///
  /// [time] is the search this belongs to; a later search makes it stale, and
  /// its results are dropped rather than shown under the newer ones.
  Future<void> loadYoutubeResults(String text, {required int time}) async {
    final List<Suggestion> result;
    try {
      result = await youtubeSearch(text);
    } catch (_) {
      // A failed request is not worth an error over the songs that are already
      // on screen: the placeholder simply goes away.
      if (time == searchId) {
        youtubeTiles.value = [];
        youtubeLoading.value = false;
      }
      return;
    }
    if (time != searchId) return;

    youtubeTiles.value = result.map(_getSongSearchTile).toList();
    youtubeLoading.value = false;
  }

  /// Asks YouTube for [text] and maps the answers to suggestions.
  static Future<List<Suggestion>> _searchYouTube(String text) async {
    final yt = YoutubeExplode();
    try {
      final fetched = await Future.wait([
        YouTubeMusicUtils.searchYouTubeVideo(text, yt),
        YouTubeMusicUtils.searchWords(text, yt),
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
      });

      final wordSuggestions = words.map(
        (e) => WordSuggestion(title: e, word: e, keywords: []),
      );

      return [...videoSuggestions, ...wordSuggestions];
    } finally {
      yt.close();
    }
  }

  Future<void> loadOfflineSongs(String text) async {
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
          SearchSort.shuffled => ShuffledSorting(random()),
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

/// The placeholders shown under the stored songs while the YouTube results are
/// on their way.
class _YoutubeResultSkeletons extends StatelessWidget {
  const _YoutubeResultSkeletons();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SongSearchTileSkeleton(),
        SongSearchTileSkeleton(),
        SongSearchTileSkeleton(),
      ],
    );
  }
}
