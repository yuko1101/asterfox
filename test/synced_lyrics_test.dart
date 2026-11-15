import 'dart:convert';

import 'package:asterfox/music/lyrics/lrc.dart';
import 'package:asterfox/music/lyrics/synced_lyrics_providers.dart';
import 'package:asterfox/widget/music_widgets/synced_lyrics_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Duration ms(int milliseconds) => Duration(milliseconds: milliseconds);

http.Response json(Object body) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {"content-type": "application/json; charset=utf-8"},
    );

void main() {
  group("Lrc", () {
    test("reads timed lines in time order", () {
      final lines = Lrc.parse("[ar: 40mP]\n"
          "[00:26.31] 間違いだらけの コミュニケーション\n"
          "[00:21.72]0と1が交差する地点\n"
          "not a line\n");
      expect(lines, [
        SyncedLyricLine(ms(21720), "0と1が交差する地点"),
        SyncedLyricLine(ms(26310), "間違いだらけの コミュニケーション"),
      ]);
    });

    test("reads fractions of any length and lines repeated at several times",
        () {
      expect(Lrc.parse("[01:02.5][01:03.005][01:04] la"), [
        SyncedLyricLine(ms(62500), "la"),
        SyncedLyricLine(ms(63005), "la"),
        SyncedLyricLine(ms(64000), "la"),
      ]);
    });

    test("applies the offset tag and drops word timings", () {
      expect(Lrc.parse("[offset:+500]\n[00:01.00] <00:01.00>a <00:01.50>b"),
          [SyncedLyricLine(ms(500), "a b")]);
    });

    test("finds nothing timed in plain lyrics", () {
      expect(Lrc.isSynced("plain\nlyrics [chorus]"), isFalse);
      expect(Lrc.toPlainText("plain\nlyrics"), "plain\nlyrics");
    });

    test("writes what it reads", () {
      final lines = [
        SyncedLyricLine(ms(9690), "The club"),
        SyncedLyricLine(ms(61000), ""),
      ];
      expect(Lrc.format(lines), "[00:09.69] The club\n[01:01.00] ");
      expect(Lrc.parse(Lrc.format(lines)), lines);
      expect(Lrc.toPlainText(Lrc.format(lines)), "The club");
    });

    test("tells the line being sung", () {
      final lines = [
        SyncedLyricLine(ms(1000), "a"),
        SyncedLyricLine(ms(2000), "b"),
        SyncedLyricLine(ms(3000), "c"),
      ];
      expect(Lrc.currentLineIndex(lines, ms(500)), -1);
      expect(Lrc.currentLineIndex(lines, ms(1000)), 0);
      expect(Lrc.currentLineIndex(lines, ms(2999)), 1);
      expect(Lrc.currentLineIndex(lines, ms(60000)), 2);
      expect(Lrc.currentLineIndex(const [], ms(0)), -1);
    });
  });

  test("Jaro-Winkler ranks like strings close to 1", () {
    expect(jaroWinkler("40mp", "40mp"), 1);
    expect(jaroWinkler("martha", "marhta"), closeTo(0.961, 0.001));
    expect(jaroWinkler("ed sheeran", "adele"), lessThan(0.9));
    expect(jaroWinkler("", "a"), 0);
  });

  group("LrcLibProvider", () {
    Map<String, dynamic> item(String artist, num duration,
            {String? synced = "[00:01.00] hi", bool instrumental = false}) =>
        {
          "trackName": "Song",
          "artistName": artist,
          "duration": duration,
          "instrumental": instrumental,
          "plainLyrics": "hi",
          "syncedLyrics": synced,
        };

    test("takes the matching artist closest in length", () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return json([
          item("Someone Else", 200),
          item("40mP", 230),
          item("40mp & 初音ミク", 205),
        ]);
      });
      final result = await LrcLibProvider(client)
          .search(title: "トリノコシティ", artist: "40mP", duration: ms(206000));

      expect(requests.single.queryParameters,
          {"track_name": "トリノコシティ", "artist_name": "40mP"});
      expect(result!.lines, [SyncedLyricLine(ms(1000), "hi")]);
      expect(result.asStoredText, "[00:01.00] hi");
    });

    test("searches the title alone when title and artist find nothing",
        () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return json(requests.length == 1 ? [] : [item("40mP", 206)]);
      });
      final result = await LrcLibProvider(client)
          .search(title: "トリノコシティ", artist: "40mP", duration: ms(206000));

      expect(requests.last.queryParameters, {"q": "トリノコシティ"});
      expect(result!.isSynced, isTrue);
    });

    test("finds nothing too far in length, instrumental or by others",
        () async {
      Future<LyricsResult?> search(List<Object> items) =>
          LrcLibProvider(MockClient((_) async => json(items)))
              .search(title: "Song", artist: "Artist", duration: ms(200000));

      expect(await search([item("Artist", 230)]), isNull);
      expect(await search([item("Artist", 200, instrumental: true)]), isNull);
      expect(await search([item("Nobody", 200)]), isNull);
      final plain = await search([item("Artist", 200, synced: null)]);
      expect(plain!.isSynced, isFalse);
      expect(plain.asStoredText, "hi");
    });
  });

  group("YouTubeMusicLyricsProvider", () {
    Map<String, dynamic> browse(List<Map<String, dynamic>> lines) => {
          "contents": {
            "elementRenderer": {
              "newElement": {
                "type": {
                  "componentType": {
                    "model": {
                      "timedLyricsModel": {
                        "lyricsData": {"timedLyricsData": lines}
                      }
                    }
                  }
                }
              }
            }
          }
        };

    test("follows the lyrics tab of the video to its timed lyrics", () async {
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.url.path.endsWith("/next")) {
          expect(body["videoId"], "abc");
          return json({
            "contents": {
              "singleColumnMusicWatchNextResultsRenderer": {
                "tabbedRenderer": {
                  "watchNextTabbedResultsRenderer": {
                    "tabs": [
                      {"tabRenderer": {}},
                      {
                        "tabRenderer": {
                          "endpoint": {
                            "browseEndpoint": {
                              "browseId": "MPLYt_x",
                              "browseEndpointContextSupportedConfigs": {
                                "browseEndpointContextMusicConfig": {
                                  "pageType": "MUSIC_PAGE_TYPE_TRACK_LYRICS"
                                }
                              }
                            }
                          }
                        }
                      }
                    ]
                  }
                }
              }
            }
          });
        }
        expect(body["browseId"], "MPLYt_x");
        return json(browse([
          {
            "lyricLine": " ♪ ",
            "cueRange": {
              "startTimeMilliseconds": "0",
              "endTimeMilliseconds": "900"
            }
          },
          {
            "lyricLine": "first",
            "cueRange": {
              "startTimeMilliseconds": "900",
              "endTimeMilliseconds": "2000"
            }
          },
        ]));
      });

      final result = await YouTubeMusicLyricsProvider(client).search("abc");
      expect(paths, ["/youtubei/v1/next", "/youtubei/v1/browse"]);
      expect(result!.lines,
          [SyncedLyricLine(ms(0), ""), SyncedLyricLine(ms(900), "first")]);
    });

    test("gives plain lyrics when the lines have no timing", () {
      final result = YouTubeMusicLyricsProvider.parseBrowse(browse([
        {"lyricLine": "a"},
        {"lyricLine": "b"},
      ]));
      expect(result!.isSynced, isFalse);
      expect(result.plain, "a\nb");
    });
  });

  test("SyncedLyricsFinder prefers timed lyrics from LRCLIB to plain ones",
      () async {
    final client = MockClient((request) async {
      if (request.url.host == "music.youtube.com") {
        if (request.url.path.endsWith("/next")) return json({});
        fail("no lyrics tab, so no browse");
      }
      return json([
        {
          "artistName": "Artist",
          "duration": 100,
          "syncedLyrics": "[00:02.00] timed",
          "plainLyrics": "timed",
        }
      ]);
    });
    final result = await SyncedLyricsFinder(client: client).search(
        title: "Song", artist: "Artist", duration: ms(100000), videoId: "v");
    expect(result!.asStoredText, "[00:02.00] timed");
  });

  group("SyncedLyricsList", () {
    final lines = [
      for (var i = 0; i < 40; i++) SyncedLyricLine(ms(i * 1000), "line $i"),
    ];

    Future<void> pump(WidgetTester tester, Duration? position,
        {void Function(SyncedLyricLine)? onTap}) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SyncedLyricsList(
              lines: lines, position: position, onTapLine: onTap),
        ),
      ));
    }

    TextStyle styleOf(WidgetTester tester, String text) => tester
        .widget<AnimatedDefaultTextStyle>(find
            .ancestor(
                of: find.text(text),
                matching: find.byType(AnimatedDefaultTextStyle))
            .first)
        .style;

    testWidgets("highlights the line being sung and scrolls to it",
        (tester) async {
      await pump(tester, ms(30500));
      await tester.pumpAndSettle();

      expect(styleOf(tester, "line 30").fontWeight, FontWeight.bold);
      expect(styleOf(tester, "line 29").fontWeight, FontWeight.normal);

      final screen = tester.getSize(find.byType(Scaffold));
      final y = tester.getCenter(find.text("line 30")).dy;
      expect(y, closeTo(screen.height / 2, screen.height / 4));
    });

    testWidgets("highlights nothing when the song isn't playing",
        (tester) async {
      await pump(tester, null);
      await tester.pumpAndSettle();
      for (final text in ["line 0", "line 1"]) {
        expect(styleOf(tester, text).fontWeight, FontWeight.normal);
      }
    });

    testWidgets("plays from a tapped line", (tester) async {
      SyncedLyricLine? tapped;
      await pump(tester, ms(0), onTap: (line) => tapped = line);
      await tester.pumpAndSettle();
      await tester.tap(find.text("line 2"));
      expect(tapped, lines[2]);
    });

    testWidgets("follows a line tapped right after scrolling by hand",
        (tester) async {
      SyncedLyricLine? tapped;
      void onTap(SyncedLyricLine line) => tapped = line;
      await pump(tester, ms(0), onTap: onTap);
      await tester.pumpAndSettle();

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      final target = find.text("line 12");
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      expect(tapped, lines[12]);

      // The player then reports the tapped line's time.
      await pump(tester, tapped!.start, onTap: onTap);
      await tester.pumpAndSettle();
      expect(styleOf(tester, "line 12").fontWeight, FontWeight.bold);
      final screen = tester.getSize(find.byType(Scaffold));
      expect(tester.getCenter(target).dy,
          closeTo(screen.height / 2, screen.height / 4));
    });
  });
}
