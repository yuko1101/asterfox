/// How the offline results are grouped.
enum SearchGrouping { none, playlist, artist }

/// Which of the stored songs are kept.
///
/// Every song the offline search can show is already stored, so there is no
/// "stored only" option: it would keep everything. What narrows the list is
/// whether the song has been downloaded to this device.
enum SearchStateFilter { all, installed }

/// Whether a song must have lyrics.
enum SearchLyricsFilter { all, withLyrics, withoutLyrics }

/// The order the offline results are shown in.
enum SearchSort { relevance, addedNewest, addedOldest, shuffled }

/// What the offline search shows, as chosen by the user.
///
/// These only describe stored songs: a suggestion fetched from YouTube has no
/// playlists, no lyrics and no date it was added, so they are only offered
/// while the offline search is on.
class SearchOptions {
  const SearchOptions({
    this.grouping = SearchGrouping.none,
    this.state = SearchStateFilter.all,
    this.lyrics = SearchLyricsFilter.all,
    this.sort = SearchSort.relevance,
  });

  final SearchGrouping grouping;
  final SearchStateFilter state;
  final SearchLyricsFilter lyrics;
  final SearchSort sort;

  /// Whether the results are shown the way they are without these options.
  bool get isDefault =>
      grouping == SearchGrouping.none &&
      state == SearchStateFilter.all &&
      lyrics == SearchLyricsFilter.all &&
      sort == SearchSort.relevance;

  SearchOptions copyWith({
    SearchGrouping? grouping,
    SearchStateFilter? state,
    SearchLyricsFilter? lyrics,
    SearchSort? sort,
  }) {
    return SearchOptions(
      grouping: grouping ?? this.grouping,
      state: state ?? this.state,
      lyrics: lyrics ?? this.lyrics,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SearchOptions &&
      other.grouping == grouping &&
      other.state == state &&
      other.lyrics == lyrics &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(grouping, state, lyrics, sort);
}
