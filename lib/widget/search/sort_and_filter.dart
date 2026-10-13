import 'dart:math';

import 'search_options.dart';
import 'suggestion.dart';

List<Suggestion> filterAndSort(
    {required List<Suggestion> list,
    required List<FilterSorting> filterSortingList}) {
  if (filterSortingList.isEmpty) return list;
  List<Suggestion> result = list;
  for (final filterSorting in filterSortingList) {
    result = filterSorting.apply(result);
  }
  return result;
}

class FilterSorting {
  List<Suggestion> apply(List<Suggestion> list) {
    return list;
  }
}

class YouTubeFilter extends FilterSorting {
  @override
  List<Suggestion> apply(List<Suggestion> list) {
    return list
        .where((suggestion) =>
            suggestion is SongSuggestion &&
            suggestion.tags.contains(SongTag.youtube))
        .toList();
  }
}

class StoredFilter extends FilterSorting {
  @override
  List<Suggestion> apply(List<Suggestion> list) {
    return list
        .where((suggestion) =>
            suggestion is SongSuggestion &&
            suggestion.tags.contains(SongTag.stored))
        .toList();
  }
}

class RelatedFilter extends FilterSorting {
  RelatedFilter(this.query);
  final String query;
  @override
  List<Suggestion> apply(List<Suggestion> list) {
    if (query.isEmpty) return list;
    return list
        .where((suggestion) => _getScore(suggestion, query) > 0)
        .toList();
  }
}

class RelevanceSorting extends FilterSorting {
  RelevanceSorting(this.query);
  final String query;
  @override
  List<Suggestion> apply(List<Suggestion> list) {
    if (query.isEmpty) return list;
    list.sort((a, b) {
      final aScore = _getScore(a, query);
      final bScore = _getScore(b, query);
      return bScore.compareTo(aScore);
    });
    return list;
  }
}

int _getScore(Suggestion suggestion, String query) {
  int score = 0;
  if (suggestion.title.toLowerCase().contains(query.toLowerCase())) score += 1;
  if (suggestion.keywords
      .any((e) => e.toLowerCase().contains(query.toLowerCase()))) {
    score += 1;
  }
  if (suggestion is SongSuggestion &&
      suggestion.lyrics != null &&
      suggestion.lyrics!.contains(query)) {
    score += 1;
  }
  return score;
}

/// Keeps the songs that have been downloaded to this device.
///
/// The offline search only ever holds stored songs, so this is the only state
/// that can narrow the list.
class InstalledFilter extends FilterSorting {
  @override
  List<Suggestion> apply(List<Suggestion> list) {
    return list
        .where((suggestion) =>
            suggestion is SongSuggestion &&
            suggestion.tags.contains(SongTag.installed))
        .toList();
  }
}

/// Keeps the songs that do or do not have lyrics.
class LyricsFilter extends FilterSorting {
  LyricsFilter(this.mode);
  final SearchLyricsFilter mode;

  @override
  List<Suggestion> apply(List<Suggestion> list) {
    if (mode == SearchLyricsFilter.all) return list;
    final wanted = mode == SearchLyricsFilter.withLyrics;
    return list.where((suggestion) {
      if (suggestion is! SongSuggestion) return false;
      return hasLyrics(suggestion) == wanted;
    }).toList();
  }
}

/// Whether [suggestion] has lyrics to show.
///
/// `lyrics` is a plain string that is empty when there are none, and only the
/// suggestions of stored songs carry it at all.
bool hasLyrics(Suggestion suggestion) =>
    suggestion is SongSuggestion &&
    suggestion.lyrics != null &&
    suggestion.lyrics!.trim().isNotEmpty;

/// Orders the songs by when they were added to the library.
class AddedSorting extends FilterSorting {
  AddedSorting({required this.newestFirst});
  final bool newestFirst;

  @override
  List<Suggestion> apply(List<Suggestion> list) {
    list.sort((a, b) {
      final aAt = _storedAt(a);
      final bAt = _storedAt(b);
      // A song without a date goes last either way, rather than sorting as if
      // it had been added in 1970.
      if (aAt == null && bAt == null) return 0;
      if (aAt == null) return 1;
      if (bAt == null) return -1;
      return newestFirst ? bAt.compareTo(aAt) : aAt.compareTo(bAt);
    });
    return list;
  }
}

int? _storedAt(Suggestion suggestion) =>
    suggestion is SongSuggestion ? suggestion.musicData?.songStoredAt : null;

/// Shows the songs in a random order.
///
/// The [Random] is given rather than made here so the shuffle can be checked in
/// a test; the search makes one per call.
class ShuffledSorting extends FilterSorting {
  ShuffledSorting(this.random);
  final Random random;

  @override
  List<Suggestion> apply(List<Suggestion> list) {
    list.shuffle(random);
    return list;
  }
}

/// A heading the results are shown under, e.g. one artist or one playlist.
class SuggestionGroup {
  SuggestionGroup(this.title, this.suggestions);

  final String title;
  final List<Suggestion> suggestions;
}

/// One playlist's songs, as the grouping needs them.
class PlaylistMembership {
  PlaylistMembership({required this.name, required this.audioIds});

  final String name;
  final Set<String> audioIds;
}

/// Arranges [list] under [grouping]'s headings, keeping their order.
///
/// A song in more than one playlist appears once under each of them, since a
/// playlist is a way of looking at the library rather than a property of a
/// song. A song in no playlist is shown under [noPlaylistTitle].
List<SuggestionGroup> groupSuggestions(
  List<Suggestion> list,
  SearchGrouping grouping, {
  required String noPlaylistTitle,
  required List<PlaylistMembership> playlists,
}) {
  if (grouping == SearchGrouping.none) return [SuggestionGroup("", list)];

  final groups = <String, List<Suggestion>>{};
  for (final suggestion in list) {
    for (final title in _groupTitles(suggestion, grouping,
        noPlaylistTitle: noPlaylistTitle, playlists: playlists)) {
      (groups[title] ??= []).add(suggestion);
    }
  }

  final titles = groups.keys.toList()..sort(_byTitle);
  // The songs of no playlist are not a playlist, so they are kept at the end
  // rather than sorted in among the names.
  if (grouping == SearchGrouping.playlist &&
      groups.containsKey(noPlaylistTitle)) {
    titles
      ..remove(noPlaylistTitle)
      ..add(noPlaylistTitle);
  }
  return [for (final title in titles) SuggestionGroup(title, groups[title]!)];
}

/// The headings [suggestion] is shown under for [grouping].
List<String> _groupTitles(
  Suggestion suggestion,
  SearchGrouping grouping, {
  required String noPlaylistTitle,
  required List<PlaylistMembership> playlists,
}) {
  if (suggestion is! SongSuggestion) return [];
  final audioId = suggestion.musicData?.audioId;

  switch (grouping) {
    case SearchGrouping.none:
      return [""];
    case SearchGrouping.artist:
      final artist = suggestion.subtitle?.trim() ?? "";
      return [artist.isEmpty ? unknownArtistTitle : artist];
    case SearchGrouping.playlist:
      // A song that is not stored cannot be reached from a playlist, so it has
      // no playlist to be shown under.
      if (audioId == null) return [noPlaylistTitle];
      final names = playlists
          .where((playlist) => playlist.audioIds.contains(audioId))
          .map((playlist) => playlist.name)
          .toList();
      return names.isEmpty ? [noPlaylistTitle] : names;
  }
}

/// The heading for a song whose artist is unknown.
const String unknownArtistTitle = "";

/// Headings are shown in a user-visible order, so they are compared without
/// case: "abba" should not sort after "Zz Top".
int _byTitle(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

