import 'package:flutter/foundation.dart';

import '../../audio_source/music_data.dart';

class SongNotifier extends ChangeNotifier
    implements ValueListenable<MusicData?> {
  SongNotifier(this.value);
  @override
  MusicData? value;

  void notify() {
    notifyListeners();
  }
}
