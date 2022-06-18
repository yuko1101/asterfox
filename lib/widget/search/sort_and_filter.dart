import 'song_search.dart';

List<SongSuggestion> filterAndSort(List<SongSuggestion> list, {List<FilterSorting>? filterSortingList}) {
  if (filterSortingList == null) return list;
  List<SongSuggestion> result = list;
  for (final filterSorting in filterSortingList) {
    result = filterSorting.apply(result);
  }
  return result;
}

class FilterSorting {
  List<SongSuggestion> apply(List<SongSuggestion> list) {
    return list;
  }
}

class YouTubeFilter extends FilterSorting {
  @override
  List<SongSuggestion> apply(List<SongSuggestion> list) {
    return list.where((suggestion) => suggestion.tags.contains(SongTag.youtube)).toList();
  }
}

class LocalFilter extends FilterSorting {
  @override
  List<SongSuggestion> apply(List<SongSuggestion> list) {
    return list.where((suggestion) => suggestion.tags.contains(SongTag.local)).toList();
  }
}

class RelatedFilter extends FilterSorting {
  RelatedFilter(this.query);
  final String query;
  @override
  List<SongSuggestion> apply(List<SongSuggestion> list) {
    if (query.isEmpty) return list;
    return list.where((suggestion) => _getScore(suggestion, query) > 0).toList();
  }
}

class RelevanceSorting extends FilterSorting {
  RelevanceSorting(this.query);
  final String query;
  @override
  List<SongSuggestion> apply(List<SongSuggestion> list) {
    if (query.isEmpty) return list;
    list.sort((a, b) {
      final aScore = _getScore(a, query);
      final bScore = _getScore(b, query);
      return bScore.compareTo(aScore);
    });
    return list;
  }
}

int _getScore(SongSuggestion suggestion, String query) {
  int score = 0;
  if (suggestion.title.toLowerCase().contains(query.toLowerCase())) score += 1;
  if (suggestion.keywords.any((e) => e.toLowerCase().contains(query.toLowerCase()))) score += 1;
  return score;
}