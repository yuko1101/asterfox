import 'dart:async';

import 'package:media_kit/media_kit.dart';

import 'music_manager.dart';

class AudioPlayer extends Player {
  bool _shuffled = false;
  List<int>? _shuffledIndices;
  final MusicManager musicManager;

  AudioPlayer(this.musicManager, {super.configuration});

  bool get shuffled => _shuffled;
  List<int>? get shuffledIndices => _shuffledIndices;

  @override
  Future<void> setShuffle(bool shuffle) async {
    _shuffled = shuffle;
    if (shuffle) {
      final medias = state.playlist.medias;
      final Map<String, int> before = {
        for (int i = 0; i < medias.length; i++) medias[i].extras!["key"]: i
      };
      await super.setShuffle(true);
      _shuffledIndices = state.playlist.medias
          .map((media) => before[media.extras!["key"]]!)
          .toList();
    } else {
      _shuffledIndices = null;
      await super.setShuffle(false);
    }
    musicManager.audioStateManager.mainNotifier.update({
      "shuffled": _shuffled,
      "shuffledIndices": _shuffledIndices,
    });
  }
}
