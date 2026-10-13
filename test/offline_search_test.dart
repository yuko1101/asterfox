import 'dart:convert';
import 'dart:io';

import 'package:asterfox/data/app_scopes.dart';
import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/database.dart';
import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/data/playlist_data.dart';
import 'package:asterfox/l10n/app_localizations.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/playlist/playlist.dart';
import 'package:asterfox/widget/search/search_options.dart';
import 'package:asterfox/widget/search/song_search.dart';
import 'package:asterfox/widget/search/sort_and_filter.dart';
import 'package:asterfox/widget/search/suggestion.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The offline search as a user gets it: the stored songs of a real database,
/// run through the options the panel offers.
///
/// `SongSearch.loadOfflineSongs` is the seam between the stored data and the
/// filter layer, so driving it covers both without a widget.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory data;
  late AppDatabase db;

  setUpAll(() async {
    data = await Directory.systemTemp.createTemp('asterfox_offline_search');
    localPath = data.path;
    tempPath = '${data.path}/temp';
  });

  tearDownAll(() async {
    if (data.existsSync()) await data.delete(recursive: true);
  });

  setUp(() async {
    // `localPath` can only be set once, so the whole run shares a directory:
    // the database and the music of each test are cleared out by hand.
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
  });

  tearDown(() async {
    LocalMusicsData.getStoredData().clear();
    PlaylistsData.getStoredData().clear();
    AppDatabase.clearInstanceForTest();
    await db.close();
  });

  /// Stores a song the way the app does, so it is reachable by the search.
  Future<void> storeSong({
    required String audioId,
    required String title,
    String author = "Author",
    String lyrics = "",
    int? storedAt,
    bool downloaded = false,
  }) async {
    final row = <String, dynamic>{
      "type": "youtube",
      "remoteAudioUrl": "https://example.com/$audioId",
      "remoteImageUrl": "https://example.com/$audioId.png",
      "title": title,
      "description": "",
      "author": author,
      "audioId": audioId,
      "id": audioId,
      "authorId": "channel",
      "duration": 1000,
      "keywords": const <String>[],
      "volume": 1.0,
      "lyrics": lyrics,
      "songStoredAt": storedAt,
      "size": null,
    };
    await db.documents.insertOnConflictUpdate(
      DocumentsCompanion.insert(
        scope: AppDatabase.userScopeOf(AppScopes.songs),
        id: audioId,
        json: _encode(row),
      ),
    );
    if (downloaded) {
      // A downloaded song is one whose info.json is on the device: that is
      // what `LocalMusicsData.isInstalled` looks for.
      await File('${data.path}/music/$audioId/info.json')
          .create(recursive: true)
          .then((file) => file.writeAsString('{}'));
    }
  }

  /// Puts a playlist in place, the way the app stores one.
  Future<void> storePlaylist(String id, String name, List<String> songs) async {
    final playlist = AppPlaylist(id: id, name: name, songs: songs);
    await db.documents.insertOnConflictUpdate(
      DocumentsCompanion.insert(
        scope: AppDatabase.userScopeOf(AppScopes.playlists),
        id: id,
        json: _encode(playlist.toJson()),
      ),
    );
  }

  Future<List<Suggestion>> search(String query) async {
    await LocalMusicsData.reloadDatabase();
    await PlaylistsData.reloadDatabase();
    final search = SongSearch();
    await search.loadOfflineSongs(query);
    return search.suggestionTiles.value
        .map((tile) => tile.suggestion)
        .toList();
  }

  test('the offline search finds the songs of the library', () async {
    await storeSong(audioId: "a", title: "Alpha");
    await storeSong(audioId: "b", title: "Beta");

    final results = await search("");

    expect(results.map((s) => s.title).toList()..sort(), ["Alpha", "Beta"]);
  });

  test('the offline search only offers stored songs', () async {
    await storeSong(audioId: "stored", title: "Stored");
    // Nothing is stored for "missing", so it is not in the library.

    final results = await search("");

    expect(results.map((s) => s.title).toList(), ["Stored"]);
  });

  test('grouping the results by playlist uses the stored playlists', () async {
    await storeSong(audioId: "in", title: "In a playlist");
    await storeSong(audioId: "loose", title: "Loose");
    await storePlaylist("p1", "Chill", ["in"]);

    final results = await search("");
    final groups = groupSuggestions(
      results,
      SearchGrouping.playlist,
      noPlaylistTitle: "No playlist",
      playlists: [
        for (final playlist in PlaylistsData.getAll())
          PlaylistMembership(
            name: playlist.name,
            audioIds: playlist.songs.toSet(),
          ),
      ],
    );

    expect(groups.map((group) => group.title).toList(), ["Chill", "No playlist"]);
    expect(
      groups.first.suggestions.map((s) => s.title).toList(),
      ["In a playlist"],
    );
    expect(groups.last.suggestions.map((s) => s.title).toList(), ["Loose"]);
  });

  test('the results can be filtered by whether the song has lyrics', () async {
    await storeSong(audioId: "with", title: "With", lyrics: "la la");
    await storeSong(audioId: "without", title: "Without");

    final results = await search("");

    final filtered = LyricsFilter(SearchLyricsFilter.withLyrics).apply(results);
    expect(filtered.map((s) => s.title).toList(), ["With"]);
  });

  test('the results can be sorted by when the song was added', () async {
    await storeSong(audioId: "old", title: "Old", storedAt: 100);
    await storeSong(audioId: "new", title: "New", storedAt: 300);

    final results = await search("");

    final sorted = AddedSorting(newestFirst: true).apply(results);
    expect(sorted.map((s) => s.title).toList(), ["New", "Old"]);
  });

  test('a song in two playlists is shown as one selectable song', () async {
    // It appears under both playlists, but it is one song: selecting it under
    // one of them has to be the same selection as under the other, or it is
    // added to the queue twice.
    await storeSong(audioId: "both", title: "Both");
    await storePlaylist("p1", "Chill", ["both"]);
    await storePlaylist("p2", "Workout", ["both"]);

    await LocalMusicsData.reloadDatabase();
    await PlaylistsData.reloadDatabase();
    final search = SongSearch();
    search.searchOptions =
        const SearchOptions().copyWith(grouping: SearchGrouping.playlist);
    await search.loadOfflineSongs("");

    final groups = search.songGroups.value;
    expect(groups.map((group) => group.title).toList(), ["Chill", "Workout"]);
    final underChill = search.tileFor(groups.first.suggestions.single);
    final underWorkout = search.tileFor(groups.last.suggestions.single);
    expect(identical(underChill, underWorkout), isTrue);
  });

  test('a later search shows the state the song is in now', () async {
    // The tiles are reused between searches, so a song that was downloaded
    // after the first search has to come back with its new state rather than
    // the tile that was built before.
    await storeSong(audioId: "song", title: "Song");
    await LocalMusicsData.reloadDatabase();
    final search = SongSearch();
    await search.loadOfflineSongs("");
    expect(
      search.tileFor(search.songGroups.value.single.suggestions.single)
          .suggestion,
      isA<SongSuggestion>().having(
        (s) => s.tags.contains(SongTag.installed),
        'installed',
        isFalse,
      ),
    );

    // Now the song is on the device.
    await File('${data.path}/music/song/info.json')
        .create(recursive: true)
        .then((file) => file.writeAsString('{}'));
    await search.loadOfflineSongs("");

    expect(
      search.tileFor(search.songGroups.value.single.suggestions.single)
          .suggestion,
      isA<SongSuggestion>().having(
        (s) => s.tags.contains(SongTag.installed),
        'installed',
        isTrue,
      ),
    );
  });

  test('filtering to downloaded songs uses the files on this device', () async {
    await storeSong(audioId: "here", title: "Here", downloaded: true);
    await storeSong(audioId: "stream", title: "Stream");

    final results = await search("");

    final filtered = InstalledFilter().apply(results);
    expect(filtered.map((s) => s.title).toList(), ["Here"]);
  });
}

String _encode(Map<String, dynamic> json) => jsonEncode(json);
