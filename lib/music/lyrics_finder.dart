import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

import '../data/local_musics_data.dart';
import 'audio_source/music_data.dart';

class LyricsFinder {
  static Future<String> search(String title, String artist) async {
    final utaNet = await getFromUtaNet(title, artist);
    return utaNet;
  }

  static Future<void> applyLyrics(MusicData song, String lyrics,
      [bool applyToAll = true]) async {
    // 既に読み込まれた音楽データを更新
    if (applyToAll) {
      for (final s in MusicData.getCreated()) {
        if (s.audioId == song.audioId) s.lyrics = lyrics;
      }
    } else {
      song.lyrics = lyrics;
    }

    // 保存されているデータを更新
    if (song.isSaved) {
      LocalMusicsData.musicData
          .get([song.audioId]).set(key: "lyrics", value: lyrics);
      await LocalMusicsData.saveData();
    }
  }

  static Future<String> getFromUtaNet(String title, String artist) async {
    final searchUrl =
        "https://www.uta-net.com/search/?Aselect=2&Bselect=3&Keyword=${Uri.encodeFull(title)}&sort=4";
    final target = Uri.parse(searchUrl);

    final searchResponse = await http.get(target);

    if (searchResponse.statusCode != 200) {
      print('ERROR: ${searchResponse.statusCode}');
      return "";
    }

    final searchDocument = parse(searchResponse.body);
    final selected = searchDocument
        .querySelectorAll("tbody.songlist-table-body > tr.border-bottom");
    if (selected.isEmpty) return "";

    final matchedList = (selected).where((element) {
      if (!element.hasChildNodes() || element.children.length < 2) {
        return false;
      }
      final artistElement = element.children[1];
      if (!artistElement.hasChildNodes()) return false;
      final String? artistName = artistElement.children[0].text;
      if (artistName == null) return false;
      if (!artistName.contains(artist)) return false;
      return true;
    });

    if (matchedList.isEmpty) return "";

    final matched = matchedList.first;

    if (!matched.children[0].hasChildNodes()) return "";

    final url =
        "https://www.uta-net.com${matched.children[0].children[0].attributes["href"]}";
    print(url);
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      print('ERROR: ${response.statusCode}');
      return "";
    }

    final document = parse(response.body);
    final lyrics = document
        .querySelector("#kashi_area")!
        .innerHtml
        .replaceAll("<br>", "\n");

    print("lyrics = $lyrics");

    return lyrics;
  }
}
