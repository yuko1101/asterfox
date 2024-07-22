import 'package:media_kit/media_kit.dart';
import 'audio_data_manager.dart';
import 'audio_handler.dart';
import 'music_manager.dart';

class MusicListener {
  MusicListener(this._musicManager, this._audioHandler) {
    _audioDataManager = AudioDataManager(_audioHandler.audioPlayer);
  }
  final MusicManager _musicManager;
  final SessionAudioHandler _audioHandler;

  late AudioDataManager _audioDataManager;

  void init() {
    _audioHandler.audioPlayer.stream.playlist.listen((sequenceState) {
      _updatePlaylistAndIndex(sequenceState);
    });
    _audioHandler.audioPlayer.stream.playing.listen((playing) {
      _updatePlaybackState(playing);
    });

    _audioHandler.audioPlayer.stream.position.listen((position) {
      _updateProgress();
    });
    _audioHandler.audioPlayer.stream.buffer.listen((buffered) {
      _updateProgress();
    });
    _audioHandler.audioPlayer.stream.playlistMode.listen((loopMode) {
      _updateLoopMode(loopMode);
    });
    _audioHandler.audioPlayer.stream.volume.listen((volume) {
      _updateVolume(volume / 100);
    });
  }

  int _lastPlaylistLength = 0;
  void _updatePlaylistAndIndex(Playlist sequenceState) {
    final sequence = sequenceState.medias;
    final currentIndex = sequenceState.index;

    _musicManager.audioStateManager.mainNotifier.update({
      "sequence": sequence,
      "currentIndex": currentIndex,
    });

    // TODO: add to settings
    if (_lastPlaylistLength == 0 && sequence.isNotEmpty) {
      // _autoPlay = true;
    }
    _lastPlaylistLength = sequence.length;
  }

  // bool _autoPlay = false;
  void _updatePlaybackState(bool playing) {
    final newAudioState = _musicManager.audioStateManager.mainNotifier.value
        .copyWith({"playing": playing});

    final playingState = newAudioState.playingState;
    if (playingState == PlayingState.unknown) {
      _audioHandler.seek(Duration.zero);
      _audioHandler.pause();
    }
    // TODO: implement this
    // if (_autoPlay) {
    //   if (playingState == PlayingState.paused) {
    //     _musicManager.play();
    //     _autoPlay = false;
    //   } else if (playingState == PlayingState.playing) {
    //     _autoPlay = false;
    //   }
    // }

    _musicManager.audioStateManager.mainNotifier.value = newAudioState;
  }

  void _updateProgress() {
    _musicManager.progressNotifier.value = _audioDataManager.progress;
  }

  void _updateLoopMode(PlaylistMode loopMode) {
    _musicManager.audioStateManager.mainNotifier.update({"loopMode": loopMode});
  }

  void _updateVolume(double volume) {
    _musicManager.audioStateManager.mainNotifier.update({"volume": volume});
  }
}
