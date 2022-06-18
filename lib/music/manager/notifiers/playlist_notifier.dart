import 'package:flutter/foundation.dart';

import '../../audio_source/music_data.dart';

class PlaylistNotifier extends ChangeNotifier
    implements ValueListenable<List<MusicData>> {
  PlaylistNotifier(this.value);
  @override
  List<MusicData> value;

  void notify() {
    notifyListeners();
  }
}
