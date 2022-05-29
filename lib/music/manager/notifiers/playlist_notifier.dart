import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:flutter/foundation.dart';

class PlaylistNotifier extends ChangeNotifier implements ValueListenable<List<MusicData>> {
  PlaylistNotifier(this.value);
  @override
  List<MusicData> value;

  void notify() {
    notifyListeners();
  }

}