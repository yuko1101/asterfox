import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'lrc.dart';

/// Lyrics a provider found: timed [lines], [plain] text, or both.
class LyricsResult {
  const LyricsResult({this.lines, this.plain});

  final List<SyncedLyricLine>? lines;
  final String? plain;

  bool get isSynced => lines != null && lines!.isNotEmpty;

  /// The lyrics as they are stored on a song: LRC when timed, else plain.
  String get asStoredText => isSynced ? Lrc.format(lines!) : (plain ?? "");
}

/// Finds lyrics with timing the way pear-desktop's synced-lyrics plugin does:
/// YouTube Music's own timed lyrics for the video, then LRCLIB by title and
/// artist. Timed lyrics from either win over plain ones.
class SyncedLyricsFinder {
  SyncedLyricsFinder({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  late final youTubeMusic = YouTubeMusicLyricsProvider(_client);
  late final lrcLib = LrcLibProvider(_client);

  Future<LyricsResult?> search({
    required String title,
    required String artist,
    required Duration duration,
    String? videoId,
  }) async {
    final results = <LyricsResult>[];
    if (videoId != null) {
      final result = await _tryOrNull(() => youTubeMusic.search(videoId));
      if (result != null && result.isSynced) return result;
      if (result != null) results.add(result);
    }
    final result = await _tryOrNull(
        () => lrcLib.search(title: title, artist: artist, duration: duration));
    if (result != null && result.isSynced) return result;
    if (result != null) results.add(result);

    for (final result in results) {
      if (result.plain != null && result.plain!.trim().isNotEmpty) {
        return result;
      }
    }
    return null;
  }

  static Future<LyricsResult?> _tryOrNull(
      Future<LyricsResult?> Function() search) async {
    try {
      return await search();
    } catch (e) {
      debugPrint("lyrics provider failed: $e");
      return null;
    }
  }
}

/// https://lrclib.net, searched by the title and artist the user gave.
class LrcLibProvider {
  LrcLibProvider(this._client);

  final http.Client _client;

  static const baseUrl = "https://lrclib.net";

  /// The longest a match may differ from the song's length.
  static const maxDurationDifference = Duration(seconds: 15);

  Future<LyricsResult?> search({
    required String title,
    required String artist,
    required Duration duration,
  }) async {
    var items = await _search({"track_name": title, "artist_name": artist});
    // Like pear-desktop with "show lyrics even if inexact", fall back to
    // searching the title alone, which finds titles written in another
    // script than the one the user typed.
    if (items.isEmpty) items = await _search({"q": title});

    final artists = _splitArtists(artist);
    final matches = items.where((item) {
      final itemArtists = _splitArtists(item["artistName"] as String? ?? "");
      var ratio = 0.0;
      for (final a in artists) {
        for (final b in itemArtists) {
          ratio = math.max(ratio, jaroWinkler(a, b));
          ratio = math.max(ratio, jaroWinkler(b, a));
        }
      }
      return ratio > 0.9;
    }).toList();

    final seconds = duration.inMilliseconds / 1000;
    double difference(Map<String, dynamic> item) =>
        ((item["duration"] as num? ?? 0) - seconds).abs();
    matches.sort((a, b) => difference(a).compareTo(difference(b)));

    if (matches.isEmpty) return null;
    final closest = matches.first;
    if (difference(closest) > maxDurationDifference.inSeconds) return null;
    if (closest["instrumental"] == true) return null;

    final synced = closest["syncedLyrics"] as String?;
    final plain = closest["plainLyrics"] as String?;
    if ((synced == null || synced.isEmpty) &&
        (plain == null || plain.isEmpty)) {
      return null;
    }
    return LyricsResult(
      lines: synced == null ? null : Lrc.parse(synced),
      plain: plain,
    );
  }

  Future<List<Map<String, dynamic>>> _search(Map<String, String> query) async {
    final uri =
        Uri.parse("$baseUrl/api/search").replace(queryParameters: query);
    final response = await _client.get(uri, headers: {
      "User-Agent": "Asterfox (https://github.com/yuko1101/asterfox)",
    });
    if (response.statusCode != 200) {
      throw Exception("LRCLIB responded ${response.statusCode}");
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) throw Exception("LRCLIB did not answer a list");
    return data.cast<Map<String, dynamic>>();
  }

  static List<String> _splitArtists(String artists) => artists
      .split(RegExp(r"[&,]"))
      .map((artist) => artist.trim().toLowerCase())
      .where((artist) => artist.isNotEmpty)
      .toList();
}

/// The lyrics tab of a video on YouTube Music. YouTube Music answers timed
/// lyrics to its mobile clients for some songs, and plain ones otherwise.
class YouTubeMusicLyricsProvider {
  YouTubeMusicLyricsProvider(this._client);

  final http.Client _client;

  static const baseUrl = "https://music.youtube.com/youtubei/v1";

  Future<LyricsResult?> search(String videoId) async {
    final next = await _post("next", {
      "videoId": videoId,
      "context": {
        "client": {
          "clientName": "WEB_REMIX",
          "clientVersion": "1.20250101.01.00"
        }
      },
    });

    final tabs = _path(next, [
      "contents",
      "singleColumnMusicWatchNextResultsRenderer",
      "tabbedRenderer",
      "watchNextTabbedResultsRenderer",
      "tabs",
    ]);
    if (tabs is! List) return null;
    String? browseId;
    for (final tab in tabs) {
      final endpoint =
          _path(tab, ["tabRenderer", "endpoint", "browseEndpoint"]);
      final pageType = _path(endpoint, [
        "browseEndpointContextSupportedConfigs",
        "browseEndpointContextMusicConfig",
        "pageType",
      ]);
      if (pageType == "MUSIC_PAGE_TYPE_TRACK_LYRICS") {
        browseId = _path(endpoint, ["browseId"]) as String?;
      }
    }
    if (browseId == null) return null;

    final browse = await _post("browse", {
      "browseId": browseId,
      // The iOS YouTube Music client, the one pear-desktop asks as.
      "context": {
        "client": {"clientName": "26", "clientVersion": "7.01.05"}
      },
    });
    return parseBrowse(browse);
  }

  /// The lyrics in a `browse` answer for a lyrics page.
  static LyricsResult? parseBrowse(Object? browse) {
    final contents = _path(browse, ["contents"]);
    final timed = _path(contents, [
      "elementRenderer",
      "newElement",
      "type",
      "componentType",
      "model",
      "timedLyricsModel",
      "lyricsData",
      "timedLyricsData",
    ]);

    if (timed is List && timed.isNotEmpty) {
      final hasTiming = _path(timed.first, ["cueRange"]) != null;
      if (hasTiming) {
        final lines = <SyncedLyricLine>[
          for (final line in timed)
            SyncedLyricLine(
              Duration(
                  milliseconds: int.parse(
                      _path(line, ["cueRange", "startTimeMilliseconds"])
                          .toString())),
              _lineText(line),
            )
        ]..sort((a, b) => a.start.compareTo(b.start));
        return LyricsResult(lines: lines);
      }
      return LyricsResult(
          plain:
              timed.map((line) => _path(line, ["lyricLine"]) ?? "").join("\n"));
    }

    final runs = _path(contents, ["messageRenderer", "text", "runs"]) ??
        _path(contents, [
          "sectionListRenderer",
          "contents",
          0,
          "musicDescriptionShelfRenderer",
          "description",
          "runs",
        ]);
    if (runs is! List) return null;
    final plain = runs.map((run) => _path(run, ["text"]) ?? "").join("\n");
    if (plain.trim().isEmpty || plain == "Lyrics not available") return null;
    return LyricsResult(plain: plain);
  }

  static String _lineText(Object? line) {
    final text = (_path(line, ["lyricLine"]) as String? ?? "").trim();
    return text == "♪" ? "" : text;
  }

  Future<Object?> _post(String endpoint, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse("$baseUrl/$endpoint?prettyPrint=false"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception("YouTube Music responded ${response.statusCode}");
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Object? _path(Object? json, List<Object> path) {
    var current = json;
    for (final key in path) {
      if (key is int && current is List && key < current.length) {
        current = current[key];
      } else if (key is String && current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}

/// The Jaro-Winkler similarity of [a] and [b], from 0 (unlike) to 1 (equal).
double jaroWinkler(String a, String b) {
  if (a == b) return 1;
  final s1 = a.runes.toList();
  final s2 = b.runes.toList();
  if (s1.isEmpty || s2.isEmpty) return 0;

  final range = math.max(0, math.max(s1.length, s2.length) ~/ 2 - 1);
  final matched1 = List.filled(s1.length, false);
  final matched2 = List.filled(s2.length, false);
  var matches = 0;
  for (var i = 0; i < s1.length; i++) {
    final from = math.max(0, i - range);
    final to = math.min(s2.length - 1, i + range);
    for (var j = from; j <= to; j++) {
      if (matched2[j] || s1[i] != s2[j]) continue;
      matched1[i] = matched2[j] = true;
      matches++;
      break;
    }
  }
  if (matches == 0) return 0;

  var transpositions = 0;
  var k = 0;
  for (var i = 0; i < s1.length; i++) {
    if (!matched1[i]) continue;
    while (!matched2[k]) {
      k++;
    }
    if (s1[i] != s2[k]) transpositions++;
    k++;
  }

  final m = matches.toDouble();
  final jaro =
      (m / s1.length + m / s2.length + (m - transpositions / 2) / m) / 3;

  var prefix = 0;
  while (prefix < math.min(4, math.min(s1.length, s2.length)) &&
      s1[prefix] == s2[prefix]) {
    prefix++;
  }
  return jaro + prefix * 0.1 * (1 - jaro);
}
