import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:asterfox/data/app_scopes.dart';
import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/database.dart';
import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/l10n/app_localizations.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/music_data/music_data.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/utils/network_utils.dart';
import 'package:asterfox/widget/search/song_search.dart';
import 'package:asterfox/widget/search/song_search_skeleton.dart';
import 'package:asterfox/widget/search/sort_and_filter.dart';
import 'package:asterfox/widget/search/suggestion.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Searching the stored songs and YouTube as one list: the stored songs come
/// back at once, and the YouTube results are added below them once the typing
/// has stopped.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory data;
  late AppDatabase db;

  setUpAll(() async {
    data = await Directory.systemTemp.createTemp('asterfox_youtube_merge');
    localPath = data.path;
    tempPath = '${data.path}/temp';
  });

  tearDownAll(() async {
    if (data.existsSync()) await data.delete(recursive: true);
  });

  setUp(() async {
    for (final suffix in ['', '-wal', '-shm']) {
      final file = File('${data.path}/asterfox.sqlite$suffix');
      if (file.existsSync()) file.deleteSync();
    }
    final music = Directory('${data.path}/music');
    if (music.existsSync()) music.deleteSync(recursive: true);

    db = AppDatabase(NativeDatabase(File('${data.path}/asterfox.sqlite')));
    AppDatabase.setInstanceForTest(db);
    await CustomColors.init();
    l10n.value = lookupAppLocalizations(const Locale('en'));

    // There is a network, so YouTube is worth searching.
    NetworkUtils.connectivityResults = [ConnectivityResult.wifi];
    NetworkUtils.minimum = ConnectivityResult.wifi;
  });

  tearDown(() async {
    LocalMusicsData.getStoredData().clear();
    AppDatabase.clearInstanceForTest();
    await db.close();
  });

  Future<void> storeSong({required String audioId, required String title}) async {
    final row = <String, dynamic>{
      "type": "youtube",
      "remoteAudioUrl": "https://example.com/$audioId",
      "remoteImageUrl": "https://example.com/$audioId.png",
      "title": title,
      "description": "",
      "author": "Author",
      "audioId": audioId,
      "id": audioId,
      "authorId": "channel",
      "duration": 1000,
      "keywords": const <String>[],
      "volume": 1.0,
      "lyrics": "",
      "songStoredAt": 1,
      "size": null,
    };
    await db.documents.insertOnConflictUpdate(
      DocumentsCompanion.insert(
        scope: AppDatabase.userScopeOf(AppScopes.songs),
        id: audioId,
        json: jsonEncode(row),
      ),
    );
  }

  /// A suggestion as YouTube returns one: a link, no stored song behind it.
  SongSuggestion fromYoutube(String title) => SongSuggestion(
        mediaUrl: "https://youtube.com/watch?v=$title",
        tags: const [SongTag.youtube],
        title: title,
        subtitle: "Channel",
        keywords: const [],
      );

  /// A suggestion as the library returns one: a song that is already stored.
  SongSuggestion storedSong(String title) {
    final musicData = MusicData<CachingDisabled>(
      type: MusicType.youtube,
      remoteAudioUrl: "https://example.com/$title",
      remoteImageUrl: "https://example.com/$title.png",
      title: title,
      description: "",
      author: "Author",
      keywords: const [],
      audioId: title,
      duration: const Duration(seconds: 1),
      volume: 1,
      lyrics: "",
      songStoredAt: 1,
      size: null,
      caching: CachingDisabled(),
    );
    return SongSuggestion(
      musicData: musicData,
      tags: const [SongTag.stored],
      title: title,
      subtitle: "Author",
      keywords: const [],
      lyrics: "",
    );
  }

  List<String> titlesOf(List<Suggestion> suggestions) =>
      suggestions.map((suggestion) => suggestion.title).toList();

  /// A search with the waiting time taken out, so the debounce does not have to
  /// be waited on in real time.
  SongSearch newSearch({required List<Suggestion> youtube}) {
    final search = SongSearch();
    search.searchDelay = Duration.zero;
    search.youtubeSearch = (_) async => youtube;
    return search;
  }

  /// Lets the debounce and the search run.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('the YouTube results are added under the stored songs', () async {
    await storeSong(audioId: 'stored', title: 'Stored song');
    await LocalMusicsData.reloadDatabase();

    final search = newSearch(youtube: [fromYoutube('From YouTube')]);
    search.query = 'song';
    search.searchResults();

    // The stored songs are there straight away, with nothing from YouTube yet.
    expect(
      titlesOf(search.songGroups.value.single.suggestions),
      ['Stored song'],
    );
    expect(search.youtubeTiles.value, isEmpty);

    await settle();

    expect(
      search.youtubeTiles.value.map((tile) => tile.suggestion.title).toList(),
      ['From YouTube'],
    );
    // And the stored songs are still shown below... above them.
    expect(
      titlesOf(search.songGroups.value.single.suggestions),
      ['Stored song'],
    );
  });

  test('a placeholder stands where the YouTube results will go', () async {
    // The list must not jump when the results arrive, so the room they will
    // take is held open from the moment the query is typed.
    final search = newSearch(youtube: [fromYoutube('From YouTube')]);
    search.searchDelay = const Duration(seconds: 5);
    search.query = 'song';
    search.searchResults();

    expect(search.youtubeLoading.value, isTrue);
    expect(search.youtubeTiles.value, isEmpty);
  });

  test('nothing is looked up on YouTube while the query is empty', () async {
    // With no query there is nothing to ask about, and no placeholder is left
    // standing over an empty list either.
    var asked = 0;
    final search = newSearch(youtube: []);
    search.searchDelay = const Duration(seconds: 5);
    search.youtubeSearch = (_) async {
      asked++;
      return [];
    };

    search.query = '';
    search.searchResults();

    expect(search.youtubeLoading.value, isFalse);
    await settle();
    expect(asked, 0, reason: 'YouTube is not asked without a query');
  });

  test('nothing is looked up on YouTube without a network', () async {
    NetworkUtils.connectivityResults = [ConnectivityResult.none];

    var asked = 0;
    final search = newSearch(youtube: []);
    search.searchDelay = const Duration(seconds: 5);
    search.youtubeSearch = (_) async {
      asked++;
      return [];
    };

    search.query = 'song';
    search.searchResults();

    expect(search.youtubeLoading.value, isFalse);
    await settle();
    expect(asked, 0, reason: 'YouTube cannot be reached anyway');
  });

  test('typing again drops the answer to the query before it', () async {
    // The stored songs follow the newest query, so an answer to an older query
    // that is still on its way must not land under them when it arrives.
    final search = SongSearch()..searchDelay = Duration.zero;
    final answers = <String, Completer<List<Suggestion>>>{};
    search.youtubeSearch = (query) {
      final answer = Completer<List<Suggestion>>();
      answers[query] = answer;
      return answer.future;
    };

    search.query = 'first';
    search.searchResults();
    await settle();

    // The first query is on its way when the second one is typed.
    search.query = 'second';
    search.searchResults();
    await settle();

    answers['second']!.complete([fromYoutube('Second')]);
    await settle();
    // The older answer arrives last, and is dropped rather than shown.
    answers['first']!.complete([fromYoutube('First')]);
    await settle();

    expect(
      search.youtubeTiles.value.map((tile) => tile.suggestion.title).toList(),
      ['Second'],
      reason: 'the older answer is dropped',
    );
  });

  test('a failed search only takes the placeholder away', () async {
    await storeSong(audioId: 'stored', title: 'Stored song');
    await LocalMusicsData.reloadDatabase();

    final search = SongSearch()..searchDelay = Duration.zero;
    search.youtubeSearch = (_) async => throw Exception('no network');

    search.query = 'song';
    search.searchResults();
    await settle();

    expect(search.youtubeLoading.value, isFalse);
    expect(
      titlesOf(search.songGroups.value.single.suggestions),
      ['Stored song'],
      reason: 'the stored songs are still shown',
    );
  });

  /// The results as they are drawn, without the database or a search of its
  /// own: the two lists are put in place and rendered.
  Future<void> pumpResults(
    WidgetTester tester, {
    required List<SongSuggestion> groups,
    required List<Suggestion> youtube,
    required bool loading,
  }) async {
    final search = SongSearch();
    // Keep buildSuggestions from starting a search of its own.
    search.query = '';
    search.lastQuery = '';
    search.songGroups.value = [
      if (groups.isNotEmpty) SuggestionGroup('', groups),
    ];
    search.youtubeTiles.value =
        youtube.map((suggestion) => search.tileFor(suggestion)).toList();
    search.youtubeLoading.value = loading;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.themes[0],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (context) => search.buildSuggestions(context)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the placeholder is under the stored songs', (tester) async {
    // It is the room the YouTube results will take, so it must not cover the
    // results that are already there.
    await pumpResults(
      tester,
      groups: [storedSong('Stored song')],
      youtube: const [],
      loading: true,
    );

    expect(find.byType(SongSearchTileSkeleton), findsWidgets);
    expect(
      tester.getTopLeft(find.byType(SongSearchTileSkeleton).first).dy,
      greaterThan(tester.getTopLeft(find.text('Stored song')).dy),
      reason: 'the placeholder is under the stored songs',
    );
  });

  testWidgets('the YouTube results are drawn under the stored songs',
      (tester) async {
    await pumpResults(
      tester,
      groups: [storedSong('Stored song')],
      youtube: [fromYoutube('From YouTube')],
      loading: false,
    );

    expect(find.text('From YouTube'), findsOneWidget);
    expect(find.byType(SongSearchTileSkeleton), findsNothing);
    expect(
      tester.getTopLeft(find.text('From YouTube')).dy,
      greaterThan(tester.getTopLeft(find.text('Stored song')).dy),
      reason: 'the YouTube results come last',
    );
  });
}

