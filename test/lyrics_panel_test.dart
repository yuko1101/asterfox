import 'package:asterfox/l10n/app_localizations.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/music_data/music_data.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/widget/music_widgets/lyrics_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MusicData<CachingDisabled> song(String title, String lyrics) =>
    MusicData<CachingDisabled>(
      type: MusicType.youtube,
      remoteAudioUrl: "https://example.com/$title",
      remoteImageUrl: "https://example.com/$title.png",
      title: title,
      description: "",
      author: "Author",
      keywords: const [],
      audioId: title,
      duration: const Duration(minutes: 3),
      volume: 1,
      lyrics: lyrics,
      songStoredAt: 1,
      size: null,
      caching: CachingDisabled(),
    );

void main() {
  setUp(() {
    l10n.value = lookupAppLocalizations(const Locale("en"));
    LyricsPanel.close();
  });

  /// The home screen's layout: the lyrics panel over the playlist, and the
  /// player's footer below them.
  Future<List<String>> pumpHome(
      WidgetTester tester, ValueNotifier<MusicData?> playing) async {
    final pressed = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.themes[0],
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  const Center(child: Text("playlist")),
                  Positioned.fill(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: LyricsPanel.shown,
                      builder: (context, shown, _) => shown
                          ? ValueListenableBuilder<MusicData?>(
                              valueListenable: playing,
                              builder: (context, song, _) =>
                                  LyricsPanelBody(song: song),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => pressed.add("play"),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => pressed.add("next"),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
    return pressed;
  }

  testWidgets("the player can be used while the lyrics are shown",
      (tester) async {
    final playing = ValueNotifier<MusicData?>(song("A", "la la la"));
    final pressed = await pumpHome(tester, playing);

    LyricsPanel.open();
    await tester.pumpAndSettle();
    expect(find.text("la la la"), findsOneWidget);
    expect(find.text("playlist").hitTestable(), findsNothing,
        reason: "the panel covers the playlist");

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.tap(find.byIcon(Icons.skip_next));
    expect(pressed, ["play", "next"]);
    expect(find.text("la la la"), findsOneWidget,
        reason: "using the player leaves the lyrics open");
  });

  testWidgets("the lyrics follow the song that is playing", (tester) async {
    final playing = ValueNotifier<MusicData?>(song("A", "first song"));
    await pumpHome(tester, playing);
    LyricsPanel.open();
    await tester.pumpAndSettle();
    expect(find.text("first song"), findsOneWidget);

    playing.value = song("B", "second song");
    await tester.pumpAndSettle();
    expect(find.text("second song"), findsOneWidget);
    expect(find.text("B"), findsOneWidget);

    playing.value = song("C", "");
    await tester.pumpAndSettle();
    expect(find.text("Search lyrics"), findsOneWidget);
  });

  testWidgets("closing or going back hides the lyrics", (tester) async {
    final playing = ValueNotifier<MusicData?>(song("A", "la la la"));
    await pumpHome(tester, playing);

    LyricsPanel.open();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Close"));
    await tester.pumpAndSettle();
    expect(find.text("la la la"), findsNothing);
    expect(find.text("playlist"), findsOneWidget);

    LyricsPanel.open();
    await tester.pumpAndSettle();
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue, reason: "back closes the lyrics, not the app");
    expect(find.text("la la la"), findsNothing);
  });
}
