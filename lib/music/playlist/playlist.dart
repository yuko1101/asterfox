import 'package:uuid/uuid.dart';

import '../../data/local_musics_data.dart';
import '../music_data/music_data.dart';

class AppPlaylist {
  AppPlaylist({
    required this.id,
    required this.name,
    required this.songs,
  });

  final String id;
  String name;
  final List<String> songs;

  /// The songs of this playlist that are stored. A song deleted from the
  /// library after it was put in the playlist is left out.
  List<MusicData<T>> getMusicDataList<T extends Caching>(T caching) => [
        for (final audioId in songs)
          if (LocalMusicsData.isStored(audioId: audioId))
            LocalMusicsData.getByAudioId<T>(
              audioId: audioId,
              caching: caching.unique(),
            ),
      ];

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "songs": songs,
    };
  }

  factory AppPlaylist.fromJson(Map<String, dynamic> json) {
    return AppPlaylist(
      id: json["id"] as String,
      name: json["name"] as String,
      songs: (json["songs"] as List).cast<String>(),
    );
  }

  factory AppPlaylist.create(String name) {
    return AppPlaylist(
      id: const Uuid().v4(),
      name: name,
      songs: [],
    );
  }
}
