import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/database.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/music_data/music_data.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/widget/search/song_search.dart';
import 'package:asterfox/widget/search/song_search_tile.dart';
import 'package:asterfox/widget/search/suggestion.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asterfox/l10n/app_localizations.dart';

/// A song tile's suggestion, built as the offline search builds one.
SongSuggestion song({
  String title = "Song",
  String lyrics = "",
  bool installed = false,
}) {
  final musicData = MusicData<CachingDisabled>(
    type: MusicType.youtube,
    remoteAudioUrl: "https://example.com/a",
    remoteImageUrl: "https://example.com/a.png",
    title: title,
    description: "",
    author: "Author",
    keywords: const [],
    audioId: title,
    duration: const Duration(seconds: 1),
    volume: 1,
    lyrics: lyrics,
    songStoredAt: 1,
    size: null,
    caching: CachingDisabled(),
  );
  return SongSuggestion(
    musicData: musicData,
    tags: [SongTag.stored, if (installed) SongTag.installed],
    title: title,
    subtitle: "Author",
    keywords: const [],
    lyrics: lyrics,
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  // `localPath` is `late final` in main.dart, so it can only be written once
  // for the whole run.
  setUpAll(() => localPath = '/nonexistent');

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    AppDatabase.setInstanceForTest(db);
    await CustomColors.init();
    l10n.value = lookupAppLocalizations(const Locale('en'));
  });

  tearDown(() async {
    AppDatabase.clearInstanceForTest();
    await db.close();
  });

  Future<void> pumpTile(WidgetTester tester, Suggestion suggestion) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.themes[0],
      home: Scaffold(
        body: SongSearchTile(suggestion: suggestion, parent: SongSearch()),
      ),
    ));
  }

  testWidgets('a song with lyrics is marked', (tester) async {
    await pumpTile(tester, song(lyrics: "la la"));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lyrics_outlined), findsOneWidget);
  });

  testWidgets('a song without lyrics is not marked', (tester) async {
    await pumpTile(tester, song());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lyrics_outlined), findsNothing);
  });

  testWidgets('the mark for the stored state is kept', (tester) async {
    // The lyrics mark is added alongside the icon that says where the song
    // comes from, rather than replacing it.
    await pumpTile(tester, song(lyrics: "la la", installed: true));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.offline_pin_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lyrics_outlined), findsOneWidget);
  });
}
