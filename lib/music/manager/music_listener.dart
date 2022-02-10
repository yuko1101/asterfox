import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/manager/music_manager.dart';
import 'package:asterfox/widget/music_widgets/audio_progress_bar.dart';
import 'package:audio_service/audio_service.dart';

class MusicListener {
  MusicListener(this._musicManager, this._audioHandler);
  final MusicManager _musicManager;
  final AudioHandler _audioHandler;
  void init() {
    _playlistChange();
    _currentSongChange();
    _playbackChange();
    _currentPositionChange();
    _bufferedPositionChange();
    _totalDurationChange();
    _currentIndexChange();


  }

  void _playlistChange() {
    _audioHandler.queue.listen((playlist) {
      playlist;
      print(playlist.length.toString() + " songs");
      _musicManager.playlistNotifier.value = playlist.map((e) => e.asMusicData()).toList();
      print("playlist: " + _musicManager.playlistNotifier.value.map((e) => e.toString()).toString());



      _updateHasNextNotifier();
    });
  }

  void _currentSongChange() {
    _audioHandler.mediaItem.listen((mediaItem) {
      print("song changed!");
      _musicManager.currentSongNotifier.value = mediaItem?.asMusicData();
    });

  }
  
  void _playbackChange() {
    _audioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        _musicManager.playingNotifier.value = PlayingState.loading;
      } else if (!isPlaying) {
        _musicManager.playingNotifier.value = PlayingState.paused;
      } else if (processingState != AudioProcessingState.completed) {
        _musicManager.playingNotifier.value = PlayingState.playing;
      } else {
        _audioHandler.seek(Duration.zero);
        _audioHandler.pause();
      }
    });
  }

  void _currentPositionChange() {
    AudioService.position.listen((position) {
      final oldState = _musicManager.progressNotifier.value;
      _musicManager.progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _bufferedPositionChange() {
    _audioHandler.playbackState.listen((playbackState) {
      final oldState = _musicManager.progressNotifier.value;
      _musicManager.progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: playbackState.bufferedPosition,
        total: oldState.total,
      );
    });
  }

  void _totalDurationChange() {
    _audioHandler.mediaItem.listen((mediaItem) {
      print("duration: " + (mediaItem?.duration?.inMilliseconds.toString() ?? ""));
      // print(mediaItem);
      final oldState = _musicManager.progressNotifier.value;
      _musicManager.progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: mediaItem?.duration ?? Duration(milliseconds: mediaItem?.asMusicData().duration ?? 0),
      );
    });
  }

  void _currentIndexChange() {
    _audioHandler.playbackState.listen((playbackState) {

      if (_musicManager.currentIndexNotifier.value != playbackState.queueIndex) {
        print("index changed!");
        _musicManager.currentIndexNotifier.value = playbackState.queueIndex;
        _updateHasNextNotifier();
      }
    });
  }

  void _updateHasNextNotifier() {
    final max = _musicManager.playlistNotifier.value.length;
    final current = _musicManager.currentIndexNotifier.value;
    // final repeatMode =
    if (current == null) {
      _musicManager.hasNextNotifier.value = false;
    } else {
      _musicManager.hasNextNotifier.value = current != max - 1;
    }
  }
}


enum PlayingState {
  paused,
  playing,
  loading,
  disabled
}