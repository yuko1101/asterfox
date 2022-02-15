import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/manager/music_manager.dart';
import 'package:asterfox/music/manager/windows/windows_audio_handler.dart';
import 'package:asterfox/widget/music_widgets/audio_progress_bar.dart';
import 'package:asterfox/widget/music_widgets/repeat_button.dart';
import 'package:audio_service/audio_service.dart';
import 'package:dart_vlc/dart_vlc.dart';

import '../music_listener.dart';

class WindowsMusicListener {
  WindowsMusicListener(this._musicManager, this._audioHandler);
  final MusicManager _musicManager;
  final WindowsAudioHandler _audioHandler;

  void init() {
    _playlistChange();
    _currentSongChange();
    _playbackChange();
    _currentPositionChange();
    // _bufferedPositionChange();
    // _totalDurationChange();
    _currentIndexChange();

  }

  void _playlistChange() {
    _musicManager.playlistNotifier.addListener(() {
      final playlist = _musicManager.playlistNotifier.value;
      print("playlist: " +
          _musicManager.playlistNotifier.value
              .map((e) => e.toString())
              .toString());

      if (playlist.isEmpty) {
        print("no songs!");
        _musicManager.currentSongNotifier.value = null;
        _setDuration(null);
      }
      _musicManager.currentShuffledIndexNotifier.value =
          _musicManager.getShuffledIndex();
      _updateHasNextNotifier();
    });
  }


  void _currentSongChange() {
    _audioHandler.getAudioPlayer().currentStream.listen((currentState) {
      final AudioBase? audio = _getSongAt(currentState.index);
      print("song changed!");
      _musicManager.currentSongNotifier.value = audio;
      _musicManager.currentShuffledIndexNotifier.value = _musicManager.getShuffledIndex();
      _updateHasNextNotifier();

      if (audio != null) {
        _musicManager.playingNotifier.value = PlayingState.paused;
      } else {
        _musicManager.playingNotifier.value = PlayingState.disabled;
      }
    });

  }

  void _playbackChange() {
    _audioHandler.getAudioPlayer().playbackStream.listen((playbackState) {
      final isPlaying = playbackState.isPlaying;
      if (!isPlaying) {
        _musicManager.playingNotifier.value = PlayingState.paused;
      } else {
        _musicManager.playingNotifier.value = PlayingState.playing;
      }
    });
  }

  void _currentPositionChange() {
    _audioHandler.getAudioPlayer().positionStream.listen((positionState) {
      final oldState = _musicManager.progressNotifier.value;
      _musicManager.progressNotifier.value = ProgressBarState(
        current: positionState.position ?? Duration.zero,
        buffered: oldState.buffered,
        total: positionState.duration ?? Duration.zero,
      );
    });
  }

  // void _bufferedPositionChange() {
  //   _audioHandler.getAudioPlayer()..listen((bufferingState) {
  //     final oldState = _musicManager.progressNotifier.value;
  //     _musicManager.progressNotifier.value = ProgressBarState(
  //       current: oldState.current,
  //       buffered: bufferingState,
  //       total: oldState.total,
  //     );
  //   });
  // }

  // void _totalDurationChange() {
  //   _audioHandler.mediaItem.listen((mediaItem) {
  //     _setDuration(mediaItem);
  //   });
  // }

  void _setDuration(MediaItem? mediaItem) {
    print("duration: " + (mediaItem?.duration?.inMilliseconds.toString() ?? ""));
    // print(mediaItem);
    final oldState = _musicManager.progressNotifier.value;
    _musicManager.progressNotifier.value = ProgressBarState(
      current: oldState.current,
      buffered: oldState.buffered,
      total: mediaItem?.duration ?? Duration(milliseconds: mediaItem?.asMusicData().duration ?? 0),
    );
  }



  void _currentIndexChange() {
    _audioHandler.getAudioPlayer().currentStream.listen((currentState) {

      if (_musicManager.currentIndexNotifier.value != currentState.index) {
        _updateIndex(currentState.index);
      }
    });
  }

  void _updateIndex(int? index) {
    print("index changed! $index (shuffled: ${_musicManager.getShuffledIndex()})");
    _musicManager.currentIndexNotifier.value = index;
    _musicManager.currentShuffledIndexNotifier.value = _musicManager.getShuffledIndex();
    _updateHasNextNotifier();
  }

  void _updateHasNextNotifier() {
    final max = _musicManager.playlistNotifier.value.length;
    final current = _musicManager.currentShuffledIndexNotifier.value;
    if (max == 0) {
      _musicManager.hasNextNotifier.value = false;
      return;
    }
    if (current == null) {
      _musicManager.hasNextNotifier.value = false;
    } else {

      if ([RepeatState.one, RepeatState.all].contains(_musicManager.repeatModeNotifier.value)) {
        _musicManager.hasNextNotifier.value = true;
        return;
      }

      _musicManager.hasNextNotifier.value = current != max - 1;
    }
  }

  AudioBase? _getSongAt(int? index) {
    if (index == null) return null;
    final playlist = _musicManager.playlistNotifier.value;
    return playlist[index];
  }
}