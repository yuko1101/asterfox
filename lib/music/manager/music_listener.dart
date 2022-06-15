import 'dart:math';

import 'package:asterfox/data/settings_data.dart';
import 'package:asterfox/widget/music_widgets/repeat_button.dart';
import 'package:just_audio/just_audio.dart';
import 'package:asterfox/music/manager/audio_handler.dart';
import 'package:asterfox/music/manager/music_manager.dart';
import 'audio_data_manager.dart';

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
  }

  void _updatePlaylistAndIndex(SequenceState? sequenceState) {
    final sequence = sequenceState?.sequence;


    final playlist = AudioDataManager.getPlaylist(sequence);
    print(playlist.map((e) => e.url));

    var currentIndex = AudioDataManager.getCurrentIndex(sequenceState?.currentIndex, sequence);
    if (playlist.isNotEmpty && currentIndex == null) {
      currentIndex = 0;
    }
    currentIndex = currentIndex != null ? min(currentIndex, playlist.length - 1) : null;

    _musicManager.playlistNotifier.value = playlist;
    _musicManager.shuffledPlaylistNotifier.value = AudioDataManager.getShuffledPlaylist(sequence, _audioHandler.audioPlayer.shuffleModeEnabled, _audioHandler.audioPlayer.shuffleIndices);
    _musicManager.currentIndexNotifier.value = currentIndex;
    _musicManager.currentShuffledIndexNotifier.value = AudioDataManager.getCurrentShuffledIndex(sequenceState?.currentIndex, sequence, sequenceState?.shuffleModeEnabled ?? false, sequenceState?.shuffleIndices);
    _musicManager.currentSongNotifier.value = playlist.isNotEmpty ? playlist[currentIndex!] : null;
    _musicManager.shuffleModeNotifier.value = sequenceState?.shuffleModeEnabled ?? false;

    _updateHasNextNotifier();
    _updateProgress();

    // notify after all notifiers are updated
    _musicManager.playlistNotifier.notify();
    _musicManager.shuffledPlaylistNotifier.notify();
    _musicManager.currentIndexNotifier.notify();
    _musicManager.currentShuffledIndexNotifier.notify();
    _musicManager.currentSongNotifier.notify();
    _musicManager.shuffleModeNotifier.notify();


  }

  void _updatePlaybackState(PlayerState playerState) {
    final playingState = AudioDataManager.getPlayingState(playerState, _audioHandler.audioPlayer.sequence);
    if (playingState == PlayingState.unknown) {
      _audioHandler.seek(Duration.zero);
      _audioHandler.pause();
    }
    _musicManager.playingStateNotifier.value = playingState;
  }

  void _updateProgress() {
    _musicManager.progressNotifier.value = _audioDataManager.progress;
  }

  void _updateLoopMode(LoopMode loopMode) {
    _musicManager.repeatModeNotifier.value = AudioDataManager.getRepeatState(loopMode);
    _updateHasNextNotifier();

  }

  void _updateHasNextNotifier() {
    final hasNext = _audioDataManager.hasNext;
    _musicManager.hasNextNotifier.value = hasNext;
  }

}

