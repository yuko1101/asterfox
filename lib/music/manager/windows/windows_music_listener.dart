import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/manager/music_manager.dart';
import 'package:asterfox/music/manager/windows/windows_audio_handler.dart';
import 'package:asterfox/widget/music_widgets/audio_progress_bar.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../music_listener.dart';

class WindowsMusicListener {
  WindowsMusicListener(this._musicManager, this._windowsAudioHandler);
  final MusicManager _musicManager;
  final WindowsAudioHandler _windowsAudioHandler;
  void init() {
    _playlistChange();
    // _currentSongChange();
    _playbackChange();
    _currentPositionChange();
    _bufferedPositionChange();
    _totalDurationChange();
    _currentIndexChange();


  }

  void _playlistChange() {
    _windowsAudioHandler.getAudioPlayer().sequenceStream.listen((list) {
      final List<AudioBase> playlist = list == null ? [] : list.map((indexedAudioSource) => indexedAudioSource.asMusicData()).toList();
      _musicManager.playlistNotifier.value = playlist;
      print("playlist: " + _musicManager.playlistNotifier.value.map((e) => e.toString()).toString());
      _updateHasNextNotifier(null, playlist.length);

      print("song changed!");
      final int? currentIndex = _windowsAudioHandler.getAudioPlayer().currentIndex;
      final isValidIndex = (currentIndex != null && currentIndex < playlist.length);
      _musicManager.currentSongNotifier.value = isValidIndex ? playlist[currentIndex!] : null;
    });
  }

  // void _currentSongChange() {
  //   _windowsAudioHandler.mediaItem.listen((mediaItem) {
  //     print("song changed!");
  //     _musicManager.currentSongNotifier.value = mediaItem?.asMusicData();
  //   });
  //
  // }

  void _playbackChange() {
    _windowsAudioHandler.getAudioPlayer().playerStateStream.listen((playbackState) {
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
        _windowsAudioHandler.seek(Duration.zero);
        _windowsAudioHandler.pause();
      }
    });
  }

  void _currentPositionChange() {
    _windowsAudioHandler.getAudioPlayer().positionStream.listen((position) {
      final oldState = _musicManager.progressNotifier.value;
      _musicManager.progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _bufferedPositionChange() {
    _windowsAudioHandler.getAudioPlayer().bufferedPositionStream.listen((duration) {
      final oldState = _musicManager.progressNotifier.value;
      _musicManager.progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: duration,
        total: oldState.total,
      );
    });
  }

  void _totalDurationChange() {
    _windowsAudioHandler.getAudioPlayer().durationStream.listen((duration) {
      print("duration: " + (duration?.inMilliseconds.toString() ?? ""));
      final oldState = _musicManager.progressNotifier.value;
      _musicManager.progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: duration ?? Duration.zero,
      );
    });
  }

  void _currentIndexChange() {
    _windowsAudioHandler.getAudioPlayer().currentIndexStream.listen((index) {

      if (_musicManager.currentIndexNotifier.value != index) {
        print("index changed!");
        _musicManager.currentIndexNotifier.value = index;
        _updateHasNextNotifier(index, null);
      }
    });
  }

  void _updateHasNextNotifier(int? current, int? max) {
    max ??= _musicManager.playlistNotifier.value.length;
    current ??= _musicManager.currentIndexNotifier.value;
    // final repeatMode =
    if (current == null) {
      _musicManager.hasNextNotifier.value = false;
    } else {
      _musicManager.hasNextNotifier.value = current != max - 1;
    }
  }
}