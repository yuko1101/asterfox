import 'dart:io';

import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/database.dart';
import 'package:asterfox/l10n/app_localizations.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/music_data/music_data.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/widget/search/search_options.dart';
import 'package:asterfox/widget/search/song_search.dart';
import 'package:asterfox/widget/search/sort_and_filter.dart';
import 'package:asterfox/widget/search/suggestion.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The grouped results, as they behave while the list is scrolled.
///
/// A heading that has been collapsed has to stay collapsed: scrolling it out
/// of view and back is not a request to open it again.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory data;
  late AppDatabase db;

  setUpAll(() async {
    data = await Directory.systemTemp.createTemp('asterfox_group_scroll');
    localPath = data.path;
    tempPath = '${data.path}/temp';
  });

  tearDownAll(() async {
    if (data.existsSync()) await data.delete(recursive: true);
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase(File('${data.path}/asterfox.sqlite')));
    AppDatabase.setInstanceForTest(db);
    await CustomColors.init();
    l10n.value = lookupAppLocalizations(const Locale('en'));
  });

  tearDown(() async {
    AppDatabase.clearInstanceForTest();
    await db.close();
  });

  SongSuggestion song(String title) {
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

  /// The search showing [groupCount] headings, each with one song, without
  /// going near the database.
  Future<SongSearch> pumpGroups(WidgetTester tester,
      {int groupCount = 12}) async {
    final search = SongSearch();
    // Keep buildSuggestions from kicking off a search of its own.
    search.query = "";
    search.lastQuery = "";
    search.searchOptions =
        const SearchOptions().copyWith(grouping: SearchGrouping.playlist);
    search.songGroups.value = [
      for (var i = 0; i < groupCount; i++)
        SuggestionGroup("Playlist $i", [song("song-$i")]),
    ];

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.themes[0],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (context) => search.buildSuggestions(context)),
      ),
    ));
    await tester.pumpAndSettle();
    return search;
  }

  /// Drags the list by [offset] and lets it settle.
  Future<void> scrollBy(WidgetTester tester, double offset) async {
    await tester.drag(find.byType(ListView), Offset(0, offset));
    await tester.pumpAndSettle();
  }

  testWidgets('a collapsed heading stays collapsed after being scrolled away',
      (tester) async {
    await pumpGroups(tester);

    // Collapse the first heading.
    expect(find.text('song-0'), findsOneWidget);
    await tester.tap(find.text('Playlist 0'));
    await tester.pumpAndSettle();
    expect(find.text('song-0'), findsNothing);

    // Scroll it out of view and back.
    await scrollBy(tester, -600);
    await scrollBy(tester, 600);

    expect(find.text('Playlist 0'), findsOneWidget);
    expect(
      find.text('song-0'),
      findsNothing,
      reason: 'the heading was opened again by scrolling',
    );
  });

  testWidgets('an expanded heading stays expanded', (tester) async {
    // The same state has to survive the other way round, or the list would
    // appear to forget what the user did with it either way.
    await pumpGroups(tester);
    expect(find.text('song-0'), findsOneWidget);

    await scrollBy(tester, -600);
    await scrollBy(tester, 600);

    expect(find.text('song-0'), findsOneWidget);
  });

  testWidgets('two headings with the same name do not share their state',
      (tester) async {
    // Two playlists can be called the same thing, and the state is saved under
    // the name, so they must not end up sharing one entry. Each heading holds
    // enough songs that the list is taller than the screen and really scrolls.
    final search = SongSearch();
    search.query = "";
    search.lastQuery = "";
    search.searchOptions =
        const SearchOptions().copyWith(grouping: SearchGrouping.playlist);
    search.songGroups.value = [
      SuggestionGroup(
          "Same name", [for (var i = 0; i < 15; i++) song("first-$i")]),
      SuggestionGroup(
          "Same name", [for (var i = 0; i < 15; i++) song("second-$i")]),
    ];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.themes[0],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (context) => search.buildSuggestions(context)),
      ),
    ));
    await tester.pumpAndSettle();

    // The list really does scroll, or the check below would prove nothing.
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .maxScrollExtent,
      greaterThan(0),
    );

    // Collapse only the first of the two.
    await tester.tap(find.text('Same name').first);
    await tester.pumpAndSettle();
    expect(find.text('first-0'), findsNothing);

    // Scroll far enough that both headings are rebuilt from what was saved,
    // which is when two of them sharing one entry would both come back closed.
    await scrollBy(tester, -1500);
    await scrollBy(tester, 1500);

    expect(
      find.text('second-0'),
      findsOneWidget,
      reason: 'the second heading was collapsed along with the first',
    );
    expect(find.text('first-0'), findsNothing);
  });
}
