import 'package:asterfox/music/music_data/music_data.dart';
import 'package:asterfox/widget/search/search_options.dart';
import 'package:asterfox/widget/search/sort_and_filter.dart';
import 'package:asterfox/widget/search/suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stored song, as the offline search builds one.
SongSuggestion song({
  required String title,
  String author = "Author",
  String lyrics = "",
  int? storedAt,
  bool installed = false,
}) {
  final musicData = MusicData<CachingDisabled>(
    type: MusicType.youtube,
    remoteAudioUrl: "https://example.com/$title",
    remoteImageUrl: "https://example.com/$title.png",
    title: title,
    description: "",
    author: author,
    keywords: const [],
    audioId: title,
    duration: const Duration(seconds: 1),
    volume: 1,
    lyrics: lyrics,
    songStoredAt: storedAt,
    size: null,
    caching: CachingDisabled(),
  );
  return SongSuggestion(
    musicData: musicData,
    tags: [
      SongTag.stored,
      if (installed) SongTag.installed,
    ],
    title: title,
    subtitle: author,
    keywords: const [],
    lyrics: lyrics,
  );
}

List<String> titlesOf(List<Suggestion> suggestions) =>
    suggestions.map((suggestion) => suggestion.title).toList();

void main() {
  test('keeping only downloaded songs drops the ones that are not', () {
    final list = <Suggestion>[
      song(title: "downloaded", installed: true),
      song(title: "streaming"),
    ];

    final result = InstalledFilter().apply(list);

    expect(titlesOf(result), ["downloaded"]);
  });

  test('filtering for lyrics keeps the songs that have them', () {
    final list = <Suggestion>[
      song(title: "has lyrics", lyrics: "la la"),
      song(title: "none"),
    ];

    final result = LyricsFilter(SearchLyricsFilter.withLyrics).apply(list);

    expect(titlesOf(result), ["has lyrics"]);
  });

  test('filtering for lyrics treats whitespace as no lyrics', () {
    final list = <Suggestion>[
      song(title: "empty", lyrics: ""),
      song(title: "blank", lyrics: "  \n "),
      song(title: "has lyrics", lyrics: "la la"),
    ];

    final result = LyricsFilter(SearchLyricsFilter.withLyrics).apply(list);

    expect(titlesOf(result), ["has lyrics"]);
  });

  test('filtering for no lyrics keeps the songs without them', () {
    final list = <Suggestion>[
      song(title: "has lyrics", lyrics: "la la"),
      song(title: "none"),
    ];

    final result = LyricsFilter(SearchLyricsFilter.withoutLyrics).apply(list);

    expect(titlesOf(result), ["none"]);
  });

  test('sorting by when added puts the newest first', () {
    final list = <Suggestion>[
      song(title: "oldest", storedAt: 100),
      song(title: "newest", storedAt: 300),
      song(title: "middle", storedAt: 200),
    ];

    final result = AddedSorting(newestFirst: true).apply(list);

    expect(titlesOf(result), ["newest", "middle", "oldest"]);
  });

  test('sorting by when added puts the oldest first', () {
    final list = <Suggestion>[
      song(title: "newest", storedAt: 300),
      song(title: "oldest", storedAt: 100),
    ];

    final result = AddedSorting(newestFirst: false).apply(list);

    expect(titlesOf(result), ["oldest", "newest"]);
  });

  test('a song with no date added goes last', () {
    // Dates are only written when a song is stored, so an older library can
    // hold songs without one. They must not sort as if added in 1970.
    final list = <Suggestion>[
      song(title: "no date"),
      song(title: "added", storedAt: 100),
    ];

    final newestFirst = AddedSorting(newestFirst: true).apply([...list]);
    final oldestFirst = AddedSorting(newestFirst: false).apply([...list]);

    expect(titlesOf(newestFirst), ["added", "no date"]);
    expect(titlesOf(oldestFirst), ["added", "no date"]);
  });

  group('grouping', () {
    test('a song in two playlists is shown under each of them', () {
      final list = <Suggestion>[
        song(title: "both"),
        song(title: "only in one"),
      ];

      final groups = groupSuggestions(
        list,
        SearchGrouping.playlist,
        noPlaylistTitle: "No playlist",
        playlists: [
          PlaylistMembership(name: "Chill", audioIds: {"both"}),
          PlaylistMembership(name: "Workout", audioIds: {"both", "only in one"}),
        ],
      );

      expect(
        groups.map((group) => group.title).toList(),
        ["Chill", "Workout"],
      );
      expect(titlesOf(groups.first.suggestions), ["both"]);
      expect(titlesOf(groups.last.suggestions), ["both", "only in one"]);
    });

    test('a song in no playlist is shown as having none', () {
      final list = <Suggestion>[song(title: "loose")];

      final groups = groupSuggestions(
        list,
        SearchGrouping.playlist,
        noPlaylistTitle: "No playlist",
        playlists: [
          PlaylistMembership(name: "Chill", audioIds: {"other"}),
        ],
      );

      expect(groups.map((group) => group.title).toList(), ["No playlist"]);
      expect(titlesOf(groups.single.suggestions), ["loose"]);
    });

    test('the songs of no playlist come after the playlists', () {
      final list = <Suggestion>[
        song(title: "loose"),
        song(title: "in a list"),
      ];

      final groups = groupSuggestions(
        list,
        SearchGrouping.playlist,
        noPlaylistTitle: "No playlist",
        playlists: [
          PlaylistMembership(name: "Zzz last name", audioIds: {"in a list"}),
        ],
      );

      expect(
        groups.map((group) => group.title).toList(),
        ["Zzz last name", "No playlist"],
      );
    });

    test('grouping by artist uses the artist of the song', () {
      final list = <Suggestion>[
        song(title: "one", author: "Beatles"),
        song(title: "two", author: "ABBA"),
      ];

      final groups = groupSuggestions(
        list,
        SearchGrouping.artist,
        noPlaylistTitle: "No playlist",
        playlists: const [],
      );

      expect(groups.map((group) => group.title).toList(), ["ABBA", "Beatles"]);
    });

    test('no grouping keeps the order it was given', () {
      final list = <Suggestion>[
        song(title: "second", author: "Beatles"),
        song(title: "first", author: "ABBA"),
      ];

      final groups = groupSuggestions(
        list,
        SearchGrouping.none,
        noPlaylistTitle: "No playlist",
        playlists: const [],
      );

      expect(groups.single.title, "");
      expect(titlesOf(groups.single.suggestions), ["second", "first"]);
    });
  });

  group('the chosen options', () {
    test('start at the values that show everything', () {
      const options = SearchOptions();

      expect(options.grouping, SearchGrouping.none);
      expect(options.state, SearchStateFilter.all);
      expect(options.lyrics, SearchLyricsFilter.all);
      expect(options.sort, SearchSort.relevance);
      expect(options.isDefault, isTrue);
    });

    test('changing one keeps the others', () {
      final options = const SearchOptions()
          .copyWith(grouping: SearchGrouping.artist, sort: SearchSort.addedNewest);

      expect(options.grouping, SearchGrouping.artist);
      expect(options.sort, SearchSort.addedNewest);
      expect(options.lyrics, SearchLyricsFilter.all);
      expect(options.isDefault, isFalse);
    });

    test('narrowing the list means they are no longer the default', () {
      expect(
        const SearchOptions().copyWith(state: SearchStateFilter.installed)
            .isDefault,
        isFalse,
      );
      expect(
        const SearchOptions()
            .copyWith(lyrics: SearchLyricsFilter.withoutLyrics)
            .isDefault,
        isFalse,
      );
    });
  });
}
