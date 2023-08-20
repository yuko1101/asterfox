import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../audio_data_manager.dart';

class AudioState extends AudioDataContainer {
  AudioState({
    required this.$sequence,
    required this.$currentIndex,
    required this.$shuffleMode,
    required this.$shuffleIndices,
    required this.$playerState,
    required this.$loopMode,
    required this.$volume,
  });

  @override
  final List<IndexedAudioSource>? $sequence;
  @override
  final int? $currentIndex;
  @override
  final bool $shuffleMode;
  @override
  final List<int>? $shuffleIndices;
  @override
  final PlayerState $playerState;
  @override
  final LoopMode $loopMode;
  @override
  final double $volume;

  AudioState copyWith(Map<String, dynamic> map) {
    return AudioState(
      $sequence: map.containsKey("sequence")
          ? map["sequence"] as List<IndexedAudioSource>?
          : $sequence,
      $currentIndex: map.containsKey("currentIndex")
          ? map["currentIndex"] as int?
          : $currentIndex,
      $shuffleMode: map.containsKey("shuffleMode")
          ? map["shuffleMode"] as bool
          : $shuffleMode,
      $shuffleIndices: map.containsKey("shuffleIndices")
          ? map["shuffleIndices"] as List<int>?
          : $shuffleIndices,
      $playerState: map.containsKey("playerState")
          ? map["playerState"] as PlayerState
          : $playerState,
      $loopMode:
          map.containsKey("loopMode") ? map["loopMode"] as LoopMode : $loopMode,
      $volume:
          map.containsKey("baseVolume") ? map["baseVolume"] as double : $volume,
    );
  }

  static final AudioState defaultState = AudioState(
    $sequence: null,
    $currentIndex: null,
    $shuffleMode: false,
    $shuffleIndices: null,
    $playerState: PlayerState(false, ProcessingState.idle),
    $loopMode: LoopMode.off,
    $volume: 1.0,
  );
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
    if (newAudioState.shuffledPlaylist != _value.shuffledPlaylist) {
      changes.add(AudioStateChange.shuffledPlaylist);
    }
    if (newAudioState.currentIndex != _value.currentIndex) {
      changes.add(AudioStateChange.currentIndex);
    }
    if (newAudioState.currentShuffledIndex != _value.currentShuffledIndex) {
      changes.add(AudioStateChange.currentShuffledIndex);
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
    if (newAudioState.$shuffleIndices != _value.$shuffleIndices) {
      changes.add(AudioStateChange.shuffledIndices);
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
      songsNotifier.value = value;
      currentSongNotifier.value = value;
      playingStateNotifier.value = value;
      repeatModeNotifier.value = value;
      hasNextNotifier.value = value;
      isShuffledNotifier.value = value;
    });
  }

  final AudioStateNotifier mainNotifier = AudioStateNotifier(
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
