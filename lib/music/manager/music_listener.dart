import 'package:just_audio/just_audio.dart';
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
    _audioHandler.audioPlayer.sequenceStateStream.listen((sequenceState) {
      _updatePlaylistAndIndex(sequenceState);
    });
    _audioHandler.audioPlayer.playerStateStream.listen((playbackState) {
      _updatePlaybackState(playbackState);
    });

    _audioHandler.audioPlayer.positionStream.listen((position) {
      _updateProgress();
    });
    _audioHandler.audioPlayer.bufferedPositionStream.listen((buffered) {
      _updateProgress();
    });
    _audioHandler.audioPlayer.loopModeStream.listen((loopMode) {
      _updateLoopMode(loopMode);
    });
    _audioHandler.audioPlayer.volumeStream.listen((volume) {
      _updateBaseVolume(volume);
    });
  }

  int _lastPlaylistLength = 0;
  void _updatePlaylistAndIndex(SequenceState? sequenceState) {
    final sequence = sequenceState?.sequence;
    final currentIndex = sequenceState?.currentIndex;

    _musicManager.audioStateManager.mainNotifier.update({
      "sequence": sequence,
      "currentIndex": currentIndex,
      "shuffleMode": sequenceState?.shuffleModeEnabled ?? false,
      "shuffleIndices": sequenceState?.shuffleIndices,
      "loopMode": sequenceState?.loopMode ?? LoopMode.off,
    });

    // TODO: add to settings
    if (_lastPlaylistLength == 0 && (sequence ?? []).isNotEmpty) {
      _autoPlay = true;
    }
    _lastPlaylistLength = (sequence ?? []).length;
  }

  bool _autoPlay = false;
  void _updatePlaybackState(PlayerState playerState) {
    final newAudioState = _musicManager.audioStateManager.mainNotifier.value
        .copyWith({"playerState": playerState});

    final playingState = newAudioState.playingState;
    if (playingState == PlayingState.unknown) {
      _audioHandler.seek(Duration.zero);
      _audioHandler.pause();
    }
    if (_autoPlay) {
      if (playingState == PlayingState.paused) {
        _musicManager.play();
        _autoPlay = false;
      } else if (playingState == PlayingState.playing) {
        _autoPlay = false;
      }
    }

    _musicManager.audioStateManager.mainNotifier.value = newAudioState;
  }

  void _updateProgress() {
    _musicManager.progressNotifier.value = _audioDataManager.progress;
  }

  void _updateLoopMode(LoopMode loopMode) {
    _musicManager.audioStateManager.mainNotifier.update({"loopMode": loopMode});
  }

  void _updateBaseVolume(double volume) {
    _musicManager.audioStateManager.mainNotifier.update({"baseVolume": volume});
  }
}
