import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../audio_data_manager.dart';

class AudioState extends AudioDataContainer {
  AudioState({
    required this.$medias,
    required this.$currentIndex,
    required this.shuffled,
    required this.$playing,
    required this.$playlistMode,
    required this.$volume,
  });

  @override
  final List<Media> $medias;
  @override
  final int? $currentIndex;
  @override
  final bool shuffled;
  @override
  final bool $playing;
  @override
  final PlaylistMode $playlistMode;
  @override
  final double $volume;

  AudioState copyWith(Map<String, dynamic> map) {
    return AudioState(
      $medias:
          map.containsKey("medias") ? map["medias"] as List<Media> : $medias,
      $currentIndex: map.containsKey("currentIndex")
          ? map["currentIndex"] as int?
          : $currentIndex,
      shuffled:
          map.containsKey("shuffled") ? map["shuffled"] as bool : shuffled,
      $playing: map.containsKey("playing") ? map["playing"] as bool : $playing,
      $playlistMode: map.containsKey("playlistMode")
          ? map["playlistMode"] as PlaylistMode
          : $playlistMode,
      $volume: map.containsKey("volume") ? map["volume"] as double : $volume,
    );
  }

  static final AudioState defaultState = AudioState(
    $medias: [],
    $currentIndex: null,
    shuffled: false,
    $playing: false,
    $playlistMode: PlaylistMode.none,
    $volume: 1.0,
  );
}

class MainAudioStateNotifier extends AudioStateNotifier {
  MainAudioStateNotifier(
    super.value,
    super.targetChanges,
  );

  /// Paused changes are changes that are not notified to listeners.
  /// The integer value is the number of processes pausing the change right now.
  final Map<String, int> _pausedChanges = {};

  void pauseChange(String change) {
    _pausedChanges[change] = (_pausedChanges[change] ?? 0) + 1;
    print("pausing $change");
  }

  void resumeChange(String change) {
    final pausingProcesses = _pausedChanges[change];
    if (pausingProcesses == null) return;
    if (pausingProcesses == 1) {
      // all processes have resumed

      _pausedChanges.remove(change);

      notifyListeners();
    } else {
      _pausedChanges[change] = pausingProcesses - 1;
    }
    print("resuming $change");
  }

  bool isChangePaused(String change) {
    final pausingProcesses = _pausedChanges[change];
    return pausingProcesses != null && pausingProcesses > 0;
  }

  AudioState getAppliedPausedState(
      AudioState oldAudioState, AudioState newAudioState) {
    return newAudioState.copyWith({
      if (isChangePaused("medias")) "medias": oldAudioState.$medias,
      if (isChangePaused("currentIndex"))
        "currentIndex": oldAudioState.$currentIndex,
      if (isChangePaused("shuffled")) "shuffled": oldAudioState.shuffled,
      if (isChangePaused("playing")) "playing": oldAudioState.$playing,
      if (isChangePaused("playlistMode"))
        "playlistMode": oldAudioState.$playlistMode,
      if (isChangePaused("volume")) "volume": oldAudioState.$volume,
    });
  }
}

class AudioStateNotifier extends ChangeNotifier
    implements ValueListenable<AudioState> {
  AudioStateNotifier(
    this._value,
    this.targetChanges,
  );

  AudioState _value;
  Set<AudioStateChange> targetChanges;

  @override
  AudioState get value => _value;
  set value(newAudioState) {
    final changes = <AudioStateChange>[];

    if (newAudioState.playlist != _value.playlist) {
      changes.add(AudioStateChange.playlist);
    }
    if (newAudioState.currentIndex != _value.currentIndex) {
      changes.add(AudioStateChange.currentIndex);
    }
    if (newAudioState.currentSong != _value.currentSong) {
      changes.add(AudioStateChange.currentSong);
    }
    if (newAudioState.playingState != _value.playingState) {
      changes.add(AudioStateChange.playingState);
    }
    if (newAudioState.repeatState != _value.repeatState) {
      changes.add(AudioStateChange.repeatState);
    }
    if (newAudioState.isShuffled != _value.isShuffled) {
      changes.add(AudioStateChange.isShuffled);
    }
    if (newAudioState.hasNext != _value.hasNext) {
      changes.add(AudioStateChange.hasNext);
    }
    if (newAudioState.currentSongVolume != _value.currentSongVolume) {
      changes.add(AudioStateChange.currentSongValue);
    }
    if (newAudioState.currentSongVolume != _value.currentSongVolume) {
      changes.add(AudioStateChange.currentSongVolume);
    }

    _value = newAudioState;

    if (changes.any((change) => targetChanges.contains(change))) {
      notifyListeners();
    }
  }

  void update(Map<String, dynamic> changes) {
    value = value.copyWith(changes);
  }
}

class AudioStateManager {
  AudioStateManager() {
    mainNotifier.addListener(() {
      final value = mainNotifier.value;
      songsNotifier.value =
          mainNotifier.getAppliedPausedState(songsNotifier.value, value);
      currentSongNotifier.value =
          mainNotifier.getAppliedPausedState(currentSongNotifier.value, value);
      playingStateNotifier.value =
          mainNotifier.getAppliedPausedState(playingStateNotifier.value, value);
      repeatModeNotifier.value =
          mainNotifier.getAppliedPausedState(repeatModeNotifier.value, value);
      hasNextNotifier.value =
          mainNotifier.getAppliedPausedState(hasNextNotifier.value, value);
      isShuffledNotifier.value =
          mainNotifier.getAppliedPausedState(isShuffledNotifier.value, value);
    });
  }

  final MainAudioStateNotifier mainNotifier = MainAudioStateNotifier(
    AudioState.defaultState,
    AudioStateChange.values.toSet(),
  );

  final AudioStateNotifier songsNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioStateChange.shuffledPlaylist,
      AudioStateChange.currentSong,
      AudioStateChange.playingState,
    },
  );

  final AudioStateNotifier currentSongNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioStateChange.currentSong,
    },
  );

  final AudioStateNotifier playingStateNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioStateChange.playingState,
    },
  );

  final AudioStateNotifier repeatModeNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioStateChange.repeatState,
    },
  );

  final AudioStateNotifier hasNextNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioStateChange.hasNext,
    },
  );

  final AudioStateNotifier isShuffledNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioStateChange.isShuffled,
    },
  );
}

enum AudioStateChange {
  playlist,
  shuffledPlaylist,
  currentIndex,
  currentShuffledIndex,
  currentSong,
  playingState,
  repeatState,
  isShuffled,
  hasNext,
  currentSongValue,
  currentSongVolume,
  shuffledIndices,
}
