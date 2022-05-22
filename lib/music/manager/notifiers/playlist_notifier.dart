import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:flutter/foundation.dart';

class PlaylistNotifier extends ChangeNotifier implements ValueListenable<List<AudioBase>> {
  PlaylistNotifier(this.value);
  @override
  List<AudioBase> value;

  void notify() {
    notifyListeners();
  }

}