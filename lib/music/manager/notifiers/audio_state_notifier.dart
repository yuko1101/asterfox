import 'package:flutter/foundation.dart';

import '../audio_data_manager.dart';

class MainAudioStateNotifier extends ChangeNotifier
    implements ValueListenable<AudioState> {
  /// Paused changes are changes that are not notified to listeners.
  /// The integer value is the number of processes pausing the change right now.
  final Map<AudioRawData, PausedState> _pausedChanges = {};

  final Set<AudioRawData> lastChanges = {};

  AudioState _value = AudioState.defaultState;
  @override
  AudioState get value => _value;

  void pauseChange(AudioRawData dataType,
      {bool faking = false, dynamic fakeValue}) {
    final pausedState = _pausedChanges.putIfAbsent(dataType, PausedState.new);
    pausedState.processCount++;
    if (faking) {
      pausedState.faking = true;
      pausedState.fakeValue = fakeValue;
    }
  }

  void resumeChange(AudioRawData dataType) {
    final pausedState = _pausedChanges[dataType];
    if (pausedState == null) return;
    pausedState.processCount--;
    if (pausedState.processCount > 0) return;

    // All processes have resumed. The sub notifiers kept the paused (or fake)
    // value, so the real one is handed to them as a change of its own.
    _pausedChanges.remove(dataType);
    lastChanges
      ..clear()
      ..add(dataType);
    notifyListeners();
  }

  bool isChangePaused(AudioRawData dataType) =>
      (_pausedChanges[dataType]?.processCount ?? 0) > 0;

  AudioState getAppliedPausedState(
      AudioState oldAudioState, AudioState newAudioState) {
    return newAudioState.copyWith({
      for (final dataType in AudioRawData.values)
        if (isChangePaused(dataType))
          dataType:
              getAppliedPausedData(dataType, oldAudioState, newAudioState),
    });
  }

  dynamic getAppliedPausedData(AudioRawData dataType, AudioState oldAudioState,
      AudioState newAudioState) {
    final pausedState = _pausedChanges[dataType];
    if (pausedState == null || pausedState.processCount <= 0) {
      return newAudioState.getRawData(dataType);
    }

    return pausedState.faking
        ? pausedState.fakeValue
        : oldAudioState.getRawData(dataType);
  }

  void update(Map<AudioRawData, dynamic> changes) {
    lastChanges.clear();
    for (final entry in changes.entries) {
      if (_value.getRawData(entry.key) != entry.value) {
        lastChanges.add(entry.key);
      }
    }
    _value = _value.copyWith(changes);
    notifyListeners();
  }
}

class AudioStateNotifier extends ChangeNotifier
    implements ValueListenable<AudioState> {
  AudioStateNotifier(
    this.targetChanges,
  );

  AudioState _value = AudioState.defaultState;
  Set<AudioRawData> targetChanges;

  @override
  AudioState get value => _value;
  set value(AudioState newValue) {
    _value = newValue;
    notifyListeners();
  }
}

class AudioStateManager {
  AudioStateManager();

  void init() {
    final subNotifiers = [
      songsNotifier,
      currentSongNotifier,
      playingStateNotifier,
      repeatStateNotifier,
      hasNextNotifier,
      shuffleNotifier,
      progressNotifier,
    ];

    mainNotifier.addListener(() {
      final state = mainNotifier.value;
      final changes = mainNotifier.lastChanges;
      for (final notifier in subNotifiers) {
        if (notifier.targetChanges.intersection(changes).isNotEmpty) {
          notifier.value = mainNotifier.getAppliedPausedState(
            notifier.value,
            state,
          );
        }
      }
    });
  }

  final MainAudioStateNotifier mainNotifier = MainAudioStateNotifier();

  final AudioStateNotifier songsNotifier = AudioStateNotifier(
    {
      AudioRawData.medias,
      AudioRawData.currentIndex,
      AudioRawData.playing,
    },
  );

  final AudioStateNotifier currentSongNotifier = AudioStateNotifier(
    {
      AudioRawData.medias,
      AudioRawData.currentIndex,
    },
  );

  final AudioStateNotifier playingStateNotifier = AudioStateNotifier(
    {
      AudioRawData.medias,
      AudioRawData.playing,
    },
  );

  final AudioStateNotifier repeatStateNotifier = AudioStateNotifier(
    {
      AudioRawData.playlistMode,
    },
  );

  final AudioStateNotifier hasNextNotifier = AudioStateNotifier(
    {
      AudioRawData.currentIndex,
      AudioRawData.medias,
      AudioRawData.playlistMode,
    },
  );

  final AudioStateNotifier shuffleNotifier = AudioStateNotifier(
    {
      AudioRawData.shuffled,
    },
  );

  final AudioStateNotifier progressNotifier = AudioStateNotifier(
    {
      AudioRawData.currentIndex,
      AudioRawData.medias,
      AudioRawData.position,
      AudioRawData.buffer,
      AudioRawData.duration,
    },
  );
}

class PausedState {
  int processCount = 0;
  bool faking = false;
  dynamic fakeValue;
}
