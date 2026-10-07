import 'dart:convert';
import 'dart:io';

/// Creates sample Asterfox data in [directory].
///
/// This is the setup for ../migration_test.dart, which needs data on disk
/// before the database is opened.
Future<void> createSampleData(String directory) async {
  await Directory(directory).create(recursive: true);

  final now = DateTime.now().millisecondsSinceEpoch;
  await File('$directory/music.json').writeAsString(jsonEncode({
    "songA": {
      "type": "youtube",
      "remoteAudioUrl": "https://example.com/a",
      "remoteImageUrl": "https://example.com/a.png",
      "title": "Song A",
      "description": "first",
      "author": "Author A",
      "audioId": "songA",
      "duration": 1000,
      "keywords": ["a"],
      "volume": 1.0,
      "lyrics": "",
      "songStoredAt": now,
      "size": null,
    },
    "songB": {
      "type": "youtube",
      "remoteAudioUrl": "https://example.com/b",
      "remoteImageUrl": "https://example.com/b.png",
      "title": "Song B",
      "description": "second",
      "author": "Author B",
      "audioId": "songB",
      "duration": 2000,
      "keywords": ["b"],
      "volume": 0.5,
      "lyrics": "la la",
      "songStoredAt": now,
      "size": 1234,
    },
  }));

  await File('$directory/playlists.json').writeAsString(jsonEncode({
    "playlistA": {
      "id": "playlistA",
      "name": "Favorites",
      "songs": ["songA", "songB"],
    },
  }));

  await File('$directory/history.json').writeAsString(jsonEncode({
    "history": [
      {"audioId": "songA", "title": "Song A", "author": "Author A", "lastPlayed": 1},
      {"audioId": "songB", "title": "Song B", "author": "Author B", "lastPlayed": 2},
    ],
  }));

  await File('$directory/settings.json').writeAsString(jsonEncode({
    "theme": "light",
    "autoDownload": true,
    "disableInterruptions": false,
    "audioChannel": "media",
  }));

  await File('$directory/device_settings.json').writeAsString(jsonEncode({
    "repeatMode": "all",
    "baseVolume": 0.25,
  }));

  await File('$directory/custom_colors.json').writeAsString(jsonEncode({
    "accent": 4278255615,
  }));
}
