import 'package:uuid/uuid.dart';

import '../../data/local_musics_data.dart';
import '../audio_source/music_data.dart';

class AppPlaylist {
  const AppPlaylist({
    required this.id,
    required this.name,
    required this.songs,
  });

  final String id;
  final String name;
  final List<String> songs;

  List<MusicData<T>> getMusicDataList<T extends Caching>(T caching) => songs
      .map(
        (audioId) => LocalMusicsData.getByAudioId(
          audioId: audioId,
          key: const Uuid().v4(),
          caching: caching,
        ),
      )
      .toList();

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
