import 'package:asterfox/widget/music_widgets/audio_progress_bar.dart';
import 'package:asterfox/widget/music_widgets/repeat_button.dart';
import 'package:just_audio/just_audio.dart';

import 'package:asterfox/music/manager/audio_handler.dart';
import 'package:asterfox/music/manager/music_manager.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';

class MusicListener {
  MusicListener(this._musicManager, this._audioHandler);
  final MusicManager _musicManager;
  final AudioPlayerHandler _audioHandler;

  void init() {
    _audioHandler.getAudioPlayer().sequenceStream.listen((sequence) {
      _updatePlaylist(sequence ?? []);
    });
    _audioHandler.getAudioPlayer().currentIndexStream.listen((index) {
      _updateCurrentIndex((_audioHandler.getAudioPlayer().sequence ?? []).isEmpty ? null : index);
    });
    _audioHandler.getAudioPlayer().playerStateStream.listen((playbackState) {
      _updatePlaybackState(playbackState);
    });

    _audioHandler.getAudioPlayer().positionStream.listen((position) {
      _updateProgress(current: position);
    });
    _audioHandler.getAudioPlayer().bufferedPositionStream.listen((buffered) {
      _updateProgress(buffered: buffered);
    });
    _audioHandler.getAudioPlayer().loopModeStream.listen((loopMode) {
      _updateLoopMode(loopMode);
    });
  }

  void _updatePlaylist(List<IndexedAudioSource> playlist) {
    if (playlist.isNotEmpty && _musicManager.currentIndexNotifier.value == null) {
      _updateCurrentIndex(0);
    }
    // if index is bigger than playlist size, set to last index
    if (_musicManager.currentIndexNotifier.value != null && playlist.length - 1 < _musicManager.currentIndexNotifier.value!) {
      _updateCurrentIndex(playlist.isEmpty ? null : playlist.length - 1);
    }
    final currentIndex = _musicManager.currentIndexNotifier.value;
    final currentSong = playlist.isEmpty || currentIndex == null ? null : playlist[currentIndex];
    _musicManager.playlistNotifier.value = playlist.map((e) => e.asAudioBase()).toList();
    _updateHasNextNotifier();
    _updateCurrentSong(currentSong?.asAudioBase());
    // test
    _musicManager.currentShuffledIndexNotifier.value = _musicManager.getShuffledIndex();
  }

  void _updateCurrentIndex(int? index) {
    _musicManager.currentIndexNotifier.value = index;

    // test
    _musicManager.currentShuffledIndexNotifier.value = _musicManager.getShuffledIndex();

    print("index changed! $index (shuffled: ${_audioHandler.getPlaylist().shuffleIndices})");
    _updateCurrentSong(index == null || _audioHandler.getAudioPlayer().sequence == null ? null : _audioHandler.getAudioPlayer().sequence![index].asAudioBase());
    _updateHasNextNotifier();
  }

  void _updateCurrentSong(AudioBase? song) {
    _musicManager.currentSongNotifier.value = song;
    _updateProgress(total: song == null ? null : Duration(milliseconds: song.duration));
  }

  void _updatePlaybackState(PlayerState playbackState) {
    _audioHandler.getAudioPlayer().playerStateStream.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        _musicManager.playingNotifier.value = PlayingState.loading;
      } else if (!isPlaying) {
        _musicManager.playingNotifier.value = PlayingState.paused;
      } else if (processingState != ProcessingState.completed) {
        _musicManager.playingNotifier.value = PlayingState.playing;
      } else {
        _audioHandler.seek(Duration.zero);
        _audioHandler.pause();
      }
    });
  }

  void _updateProgress({Duration? current, Duration? buffered, Duration? total}) {
    final oldState = _musicManager.progressNotifier.value;
    final newState = ProgressBarState(
      current: current ?? oldState.current,
      buffered: buffered ?? oldState.buffered,
      total: total ?? oldState.total,
    );
    _musicManager.progressNotifier.value = newState;
  }

  void _updateLoopMode(LoopMode loopMode) {
    _musicManager.repeatModeNotifier.value = loopModeToRepeatState(loopMode);
    _updateHasNextNotifier();
  }

  void _updateHasNextNotifier() {
    final max = _audioHandler.getAudioPlayer().sequence?.length ?? 0;
    final current = _audioHandler.getAudioPlayer().currentIndex;
    if (max == 0) {
      _musicManager.hasNextNotifier.value = false;
      return;
    }
    if (current == null) {
      _musicManager.hasNextNotifier.value = false;
      return;
    }
    if ([RepeatState.one, RepeatState.all].contains(_musicManager.repeatModeNotifier.value)) {
      _musicManager.hasNextNotifier.value = true;
      return;
    }
    _musicManager.hasNextNotifier.value = current < max - 1;
  }

}

enum PlayingState {
  paused,
  playing,
  loading,
  disabled
}