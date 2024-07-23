import 'package:flutter/foundation.dart';

import '../audio_data_manager.dart';

class MainAudioStateNotifier extends AudioStateNotifier {
  MainAudioStateNotifier(
    super.value,
    super.targetChanges,
  );

  /// Paused changes are changes that are not notified to listeners.
  /// The integer value is the number of processes pausing the change right now.
  final Map<AudioRawData, int> _pausedChanges = {};

  void pauseChange(AudioRawData dataType) {
    _pausedChanges[dataType] = (_pausedChanges[dataType] ?? 0) + 1;
    print("pausing $dataType");
  }

  void resumeChange(AudioRawData dataType) {
    final pausingProcesses = _pausedChanges[dataType];
    if (pausingProcesses == null) return;
    if (pausingProcesses == 1) {
      // all processes have resumed

      _pausedChanges.remove(dataType);

      notifyListeners();
    } else {
      _pausedChanges[dataType] = pausingProcesses - 1;
    }
    print("resuming $dataType");
  }

  bool isChangePaused(AudioRawData dataType) {
    final pausingProcesses = _pausedChanges[dataType];
    return pausingProcesses != null && pausingProcesses > 0;
  }

  AudioState getAppliedPausedState(
      AudioState oldAudioState, AudioState newAudioState) {
    return newAudioState.copyWith({
      for (final dataType in AudioRawData.values)
        if (isChangePaused(dataType))
          dataType: oldAudioState.getRawData(dataType),
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
  Set<AudioRichData> targetChanges;

  @override
  AudioState get value => _value;
  set value(newAudioState) {
    final changes = <AudioRichData>[];

    if (newAudioState.playlist != _value.playlist) {
      changes.add(AudioRichData.playlist);
    }
    if (newAudioState.currentIndex != _value.currentIndex) {
      changes.add(AudioRichData.currentIndex);
    }
    if (newAudioState.currentSong != _value.currentSong) {
      changes.add(AudioRichData.currentSong);
    }
    if (newAudioState.playingState != _value.playingState) {
      changes.add(AudioRichData.playingState);
    }
    if (newAudioState.repeatState != _value.repeatState) {
      changes.add(AudioRichData.repeatState);
    }
    if (newAudioState.shuffled != _value.shuffled) {
      changes.add(AudioRichData.shuffled);
    }
    if (newAudioState.hasNext != _value.hasNext) {
      changes.add(AudioRichData.hasNext);
    }
    if (newAudioState.currentSongVolume != _value.currentSongVolume) {
      changes.add(AudioRichData.currentSongVolume);
    }

    _value = newAudioState;

    if (changes.any((change) => targetChanges.contains(change))) {
      notifyListeners();
    }
  }

  void update(Map<AudioRawData, dynamic> changes) {
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
      repeatStateNotifier.value =
          mainNotifier.getAppliedPausedState(repeatStateNotifier.value, value);
      hasNextNotifier.value =
          mainNotifier.getAppliedPausedState(hasNextNotifier.value, value);
      shuffleNotifier.value =
          mainNotifier.getAppliedPausedState(shuffleNotifier.value, value);
    });
  }

  final MainAudioStateNotifier mainNotifier = MainAudioStateNotifier(
    AudioState.defaultState,
    AudioRichData.values.toSet(),
  );

  final AudioStateNotifier songsNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioRichData.playlist,
      AudioRichData.currentSong,
      AudioRichData.playingState,
    },
  );

  final AudioStateNotifier currentSongNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioRichData.currentSong,
    },
  );

  final AudioStateNotifier playingStateNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioRichData.playingState,
    },
  );

  final AudioStateNotifier repeatStateNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioRichData.repeatState,
    },
  );

  final AudioStateNotifier hasNextNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioRichData.hasNext,
    },
  );

  final AudioStateNotifier shuffleNotifier = AudioStateNotifier(
    AudioState.defaultState,
    {
      AudioRichData.shuffled,
    },
  );
}
