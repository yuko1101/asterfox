import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/database.dart';
import 'package:asterfox/l10n/app_localizations.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/manager/song_preview.dart';
import 'package:asterfox/music/music_data/music_data.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/widget/preview/preview_bar.dart';
import 'package:asterfox/widget/preview/related_videos_screen.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide MusicData;

import 'support/fake_preview.dart';

/// A video as YouTube reports one in a list of related videos.
Video video(String id, {String title = "Title"}) => Video(
      VideoId(id),
      title,
      "Channel",
      ChannelId("UCabcdefghijklmnopqrstuv"),
      null,
      null,
      null,
      "",
      const Duration(minutes: 3, seconds: 20),
      ThumbnailSet(id),
      const [],
      const Engagement(1000, null, null),
      false,
    );

MusicData<CachingDisabled> song(String audioId) => MusicData<CachingDisabled>(
      type: MusicType.youtube,
      remoteAudioUrl: "https://example.com/$audioId",
      remoteImageUrl: "https://example.com/$audioId.png",
      title: audioId,
      description: "",
      author: "Author",
      keywords: const [],
      audioId: audioId,
      duration: const Duration(seconds: 100),
      volume: 1,
      lyrics: "",
      songStoredAt: 1,
      size: null,
      caching: CachingDisabled(),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

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

  /// The screen, with everything that reaches YouTube and libmpv replaced.
  Future<FakePreviewPlayer> pumpScreen(
    WidgetTester tester, {
    required List<Video> videos,
    Future<List<Video>> Function(String audioId)? fetch,
  }) async {
    final player = FakePreviewPlayer();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.themes[0],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RelatedVideosScreen(
        song: song("song"),
        fetchRelated: fetch ?? (_) async => videos,
        // The song heard is the one the video is about, which is what the app
        // does: a preview is heard from the url of the video.
        fetchMusicData: (url) async => song("video"),
        addToQueue: (_) async {},
        createPreview: () => SongPreview(createPlayer: () => player),
      ),
    ));
    await tester.pumpAndSettle();
    return player;
  }

  testWidgets('the videos YouTube related to the song are listed',
      (tester) async {
    await pumpScreen(tester, videos: [
      video("aaaaaaaaaaa", title: "Related one"),
      video("bbbbbbbbbbb", title: "Related two"),
    ]);

    expect(find.text("Related one"), findsOneWidget);
    expect(find.text("Related two"), findsOneWidget);
    // Who made each video. Its length and its view count are not shown: the
    // library reports neither of them correctly (see the row's comment).
    expect(find.text("Channel"), findsNWidgets(2));
  });

  testWidgets('a video is heard on the preview when its row is tapped',
      (tester) async {
    final player = await pumpScreen(tester, videos: [
      video("aaaaaaaaaaa", title: "Related one"),
    ]);

    await tester.tap(find.text("Related one"));
    await tester.pumpAndSettle();

    // What is heard is the audio of the song, not the page of the video.
    expect(player.opened, ["https://example.com/video"]);
    // The bar a preview is steered with stands at the bottom of the screen.
    expect(find.byType(PreviewBar), findsOneWidget);
  });

  testWidgets('the row of the video that is heard stops it', (tester) async {
    final player = await pumpScreen(tester, videos: [
      video("aaaaaaaaaaa", title: "Related one"),
    ]);

    // Before anything is heard, the row offers to add the video to the queue.
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsNothing);

    await tester.tap(find.text("Related one"));
    await tester.pumpAndSettle();

    // While it is heard, the same row offers to stop it.
    expect(find.byIcon(Icons.stop), findsOneWidget);

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    expect(player.stops, 1);
    expect(find.byIcon(Icons.stop), findsNothing);
    expect(find.byType(PreviewBar), findsNothing);
  });

  testWidgets('the button of a row puts the video in the queue instead',
      (tester) async {
    // Hearing a video and keeping it are two decisions, so the row hears it and
    // the button next to it keeps it.
    final added = <String>[];
    final player = FakePreviewPlayer();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.themes[0],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RelatedVideosScreen(
        song: song("song"),
        fetchRelated: (_) async => [video("aaaaaaaaaaa", title: "Related one")],
        fetchMusicData: (url) async => song("video"),
        addToQueue: (url) async => added.add(url),
        createPreview: () => SongPreview(createPlayer: () => player),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pumpAndSettle();

    expect(added, ["https://www.youtube.com/watch?v=aaaaaaaaaaa"]);
    expect(player.opened, isEmpty, reason: "the queue button does not hear it");
    expect(find.byType(PreviewBar), findsNothing);
  });

  testWidgets('a list with nothing related says so', (tester) async {
    await pumpScreen(tester, videos: const []);

    expect(find.text(l10n.value.no_related_videos), findsOneWidget);
  });

  testWidgets('a request that failed says so', (tester) async {
    await pumpScreen(
      tester,
      videos: const [],
      fetch: (_) async => throw Exception("no network"),
    );

    expect(find.text(l10n.value.song_unable_to_load), findsOneWidget);
    expect(find.text(l10n.value.no_related_videos), findsNothing);
  });

  testWidgets('the videos are fetched for the song of the screen',
      (tester) async {
    final asked = <String>[];
    await pumpScreen(
      tester,
      videos: [video("aaaaaaaaaaa")],
      fetch: (audioId) async {
        asked.add(audioId);
        return [video("aaaaaaaaaaa")];
      },
    );

    expect(asked, ["song"]);
  });
}
