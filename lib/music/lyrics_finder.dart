import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

import '../data/local_musics_data.dart';
import '../system/firebase/cloud_firestore.dart';
import 'lyrics/synced_lyrics_providers.dart';
import 'music_data/music_data.dart';
import 'music_data/youtube_music_data.dart';

class LyricsFinder {
  /// Lyrics for the song titled [title] by [artist], as stored on a song:
  /// LRC when they come with timing, else plain text, or "" when none.
  ///
  /// Timed lyrics are looked for first, the way pear-desktop does (YouTube
  /// Music for [song]'s video, then LRCLIB), then plain ones.
  static Future<String> search(String title, String artist,
      {MusicData? song}) async {
    final found = await SyncedLyricsFinder().search(
      title: title,
      artist: artist,
      duration: song?.duration ?? Duration.zero,
      videoId: song is YouTubeMusicData ? song.id : null,
    );
    if (found != null && found.isSynced) return found.asStoredText;

    final google = await getFromGoogle(title, artist);
    if (google.isNotEmpty) return google;
    final utaNet = await getFromUtaNet(title, artist);
    if (utaNet.isNotEmpty) return utaNet;
    return found?.asStoredText ?? "";
  }

  static Future<void> applyLyrics(MusicData song, String lyrics,
      [bool applyToAll = true]) async {
    // 既に読み込まれた音楽データを更新
    if (applyToAll) {
      for (final s in MusicData.getCreated().values) {
        if (s.audioId == song.audioId) s.lyrics = lyrics;
      }
    } else {
      song.lyrics = lyrics;
    }

    // 保存されているデータを更新
    if (song.isStored) {
      await LocalMusicsData.save(song);
      await CloudFirestoreManager.addOrUpdateSongs([song]);
    }
  }

  static Future<String> getFromUtaNet(String title, String artist) async {
    try {
      final searchResponse = await http.get(Uri.https(
        "www.uta-net.com",
        "/search/",
        {"Aselect": "2", "Bselect": "3", "Keyword": title, "sort": "4"},
      ));
      if (searchResponse.statusCode != 200) return "";

      // A row is the title cell, then the artist cell.
      final rows = parse(searchResponse.body)
          .querySelectorAll("tbody.songlist-table-body > tr.border-bottom");
      final matched = rows.where((row) {
        if (row.children.length < 2) return false;
        final artistCell = row.children[1];
        return artistCell.children.isNotEmpty &&
            artistCell.children[0].text.contains(artist);
      }).firstOrNull;
      final href = matched?.children[0].querySelector("a")?.attributes["href"];
      if (href == null) return "";

      final response = await http.get(Uri.https("www.uta-net.com", href));
      if (response.statusCode != 200) return "";

      final lyricsArea = parse(response.body).querySelector("#kashi_area");
      return lyricsArea?.innerHtml.replaceAll("<br>", "\n") ?? "";
    } on Exception {
      return "";
    }
  }

  static Future<String> getFromGoogle(String title, String artist) async {
    try {
      final query = "$title $artist 歌詞";
      final userAgent =
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36";
      final searchUrl =
          "https://www.google.com/search?q=${Uri.encodeQueryComponent(query)}";

      final response = await http
          .get(Uri.parse(searchUrl), headers: {"User-Agent": userAgent});

      final doc = parse(response.body);

      final lyricsNode = doc.querySelector(
          "div[data-attrid='kc:/music/recording_cluster:lyrics']");
      if (lyricsNode == null) return "";

      final lyrics =
          lyricsNode.firstChild?.nodes[1].firstChild?.firstChild?.nodes[1].nodes
              .map((node) => node.children.map((e) {
                    if (e.localName == "br") return "\n";
                    return e.text;
                  }).join(""))
              .join("\n\n");

      return lyrics ?? "";
    } catch (e) {
      return "";
    }
  }
}
