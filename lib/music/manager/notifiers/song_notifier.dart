import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:flutter/foundation.dart';

class SongNotifier extends ChangeNotifier implements ValueListenable<MusicData?> {
  SongNotifier(this.value);
  @override
  MusicData? value;

  void notify() {
    notifyListeners();
  }

}