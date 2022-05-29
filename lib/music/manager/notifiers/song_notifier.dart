import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:flutter/foundation.dart';

class SongNotifier extends ChangeNotifier implements ValueListenable<AudioBase?> {
  SongNotifier(this.value);
  @override
  AudioBase? value;

  void notify() {
    notifyListeners();
  }

}