import 'dart:async';

import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/song_history_data.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/widget/option_widgets/option_switch.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:easy_app/utils/network_utils.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/local_musics_data.dart';
import '../../music/audio_source/music_data.dart';
import '../../music/audio_source/youtube_music_data.dart';
import '../../system/exceptions/network_exception.dart';
import '../../system/home_screen_music_manager.dart';
import '../../music/utils/youtube_music_utils.dart';
import 'song_search_tile.dart';
import 'sort_and_filter.dart';

class SongSearch extends SearchDelegate<String> {
  SongSearch({this.animationController});
  final AnimationController? animationController;

  final ValueNotifier<bool> multiSelectMode = ValueNotifier(false);

  final List<SongSearchTile> selectedTiles = [];

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
        color: Theme.of(context).textTheme.bodyText1?.color,
        tooltip: Language.getText("clear"),
        onPressed: () {
          query = "";
        },
      ),
      IconButton(
        icon: const Icon(Icons.tune),
        color: Theme.of(context).textTheme.bodyText1?.color,
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
                          title: Text(Language.getText("offline_search")),
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
        color: Theme.of(context).textTheme.bodyText1?.color,
        tooltip: Language.getText("search"),
        onPressed: () {
          if (multiSelectMode.value) {
            addSuggestionsToQueue(
                selectedTiles.map((tile) => tile.suggestion).toList());
          } else {
            if (query.isEmpty || query == "") return;
            search(context, query);
          }
          close(context, "");
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

  @override
  void showResults(BuildContext context) {
    if (multiSelectMode.value) {
      addSuggestionsToQueue(
          selectedTiles.map((tile) => tile.suggestion).toList());
    } else {
      search(context, query);
    }
    close(context, "");
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
    return SingleChildScrollView(
      child: Column(
        children: [
          ValueListenableBuilder<List<SongSearchTile>>(
            valueListenable: otherSelectedTilesNotifier,
            builder: (context, value, child) => Visibility(
              visible: value.isNotEmpty,
              child: ExpansionTile(
                title: Text(Language.getText("selected_songs")),
                children: value,
              ),
            ),
          ),
          ValueListenableBuilder<List<SongSearchTile>>(
            valueListenable: suggestionTiles,
            builder: (_, value, __) => ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) => value[index],
              itemCount: value.length,
            ),
          ),
        ],
      ),
    );
  }

  void search(BuildContext context, String text) async {
    try {
      await HomeScreenMusicManager.addSongBySearch(text, context: context);
    } on NetworkException {
      Fluttertoast.showToast(msg: Language.getText("network_not_accessible"));
    }
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
        .map((e) => SongSuggestion(
            tags: [SongTag.word], title: e, word: e, keywords: []))
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
              .any((s2) => _isSameSuggestion(s1.suggestion, s2.suggestion)))
          .toList();
      loading.value = false;
    }
  }

  void loadOfflineSongs(String text) async {
    loading.value = true;
    print("loading offline songs");
    final List<SongSuggestion> list = [];

    final List<MusicData> storedSongs =
        LocalMusicsData.getAll(isTemporary: true);
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

    final List<SongSuggestion> result = filterAndSort(
      list: list,
      filterSortingList: [RelatedFilter(text), RelevanceSorting(text)],
    );
    suggestionTiles.value = result.map((s) => _getSongSearchTile(s)).toList();
    // suggestionTiles.valueに含まれていない、選択されたSongSearchTile
    otherSelectedTilesNotifier.value = selectedTiles
        .where((s1) => !suggestionTiles.value
            .any((s2) => _isSameSuggestion(s1.suggestion, s2.suggestion)))
        .toList();
    loading.value = false;
  }

  SongSearchTile _getSongSearchTile(SongSuggestion songSuggestion) {
    if (selectedTiles
        .any((s) => _isSameSuggestion(s.suggestion, songSuggestion))) {
      final found = selectedTiles
          .firstWhere((s) => _isSameSuggestion(s.suggestion, songSuggestion));
      return found;
    } else {
      return SongSearchTile(suggestion: songSuggestion, parent: this);
    }
  }

  bool _isSameAudioId(SongSuggestion s1, SongSuggestion s2) =>
      (s1.musicData != null &&
          s2.musicData != null &&
          s1.musicData!.audioId == s2.musicData!.audioId);
  bool _isSameUrl(SongSuggestion s1, SongSuggestion s2) =>
      (s1.mediaUrl != null && s1.mediaUrl == s2.mediaUrl);

  bool _isSameWord(SongSuggestion s1, SongSuggestion s2) =>
      (s1.word != null && s1.word == s2.word);

  bool _isSameSuggestion(SongSuggestion s1, SongSuggestion s2) =>
      (_isSameAudioId(s1, s2) || _isSameUrl(s1, s2) || _isSameWord(s1, s2));

  void setQuery(newQuery) => query = newQuery;

  Future<void> addSuggestionsToQueue(List<SongSuggestion> suggestions) async {
    await HomeScreenMusicManager.addSongs(
      count: suggestions.length,
      musicDataList: suggestions
          .where((s) => s.musicData != null)
          .map(
            (s) =>
            s.musicData!.renew(isTemporary: false, key: const Uuid().v4()),
      )
          .toList(),
      mediaUrlList: suggestions
          .where((s) => s.mediaUrl != null && s.musicData == null)
          .map((s) => s.mediaUrl!)
          .toList(),
    );
  }
}

class SongSuggestion {
  SongSuggestion({
    this.musicData,
    this.mediaUrl,
    this.word,
    required this.tags,
    required this.title,
    this.subtitle,
    required this.keywords,
    this.lyrics,
  }) {
    assert(musicData != null || word != null || mediaUrl != null);
    // タグにSongTag.wordを含む場合にはwordはnullにはならず、
    // 含まない場合にはnullになる必要がある
    assert((tags.contains(SongTag.word) && word != null) ||
        (!tags.contains(SongTag.word) && word == null));
  }
  final MusicData? musicData;
  final String? mediaUrl;
  final String? word;

  final List<SongTag> tags;
  final String title;
  final String? subtitle;
  final List<String> keywords;
  final String? lyrics;
}

enum SongTag { installed, stored, youtube, word }
