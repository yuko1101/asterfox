import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:easy_app/utils/os.dart';
import 'package:flutter/cupertino.dart';

import '../../data/device_settings_data.dart';
import '../../data/local_musics_data.dart';
import '../../data/settings_data.dart';
import '../../utils/math.dart';
import '../../widget/music_widgets/audio_progress_bar.dart';
import '../../widget/music_widgets/repeat_button.dart';
import '../../widget/music_widgets/volume_widget.dart';
import '../audio_source/music_data.dart';
import 'audio_data_manager.dart';
import 'audio_handler.dart';
import 'music_listener.dart';
import 'notifiers/audio_state_notifier.dart';

class MusicManager {
  MusicManager(this.showNotification);
  final bool showNotification;

  late final SessionAudioHandler _audioHandler;
  late final AudioSession _audioSession;
  late final AudioDataManager audioDataManager;

  static bool windowsMode = OS.getOS() == OSType.windows;

  // notifiers
  final audioStateManager = AudioStateManager();

  final progressNotifier = ProgressNotifier();
  final muteNotifier = ValueNotifier<bool>(false);
  final baseVolumeNotifier = ValueNotifier<double>(1.0);

  Future<void> init() async {
    final bool handleInterruptions =
        !SettingsData.getValue(key: "disableInterruptions");
    if (!windowsMode && showNotification) {
      _audioHandler = await AudioService.init(
          builder: () => SessionAudioHandler(true, handleInterruptions),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'net.asterfox.app.channel.audio',
            androidNotificationChannelName: 'Asterfox Music',
            androidStopForegroundOnPause: true,
            androidShowNotificationBadge: true,
          ));
    } else {
      print("windowsMode");
      _audioHandler = SessionAudioHandler(false, handleInterruptions);
    }
    MusicListener(this, _audioHandler).init();
    audioDataManager = AudioDataManager(_audioHandler.audioPlayer);
  }

  Future<void> play() async {
    print(
        "Played a playlist: ${audioDataManager.playlist.length.toString()} songs");
    await _audioHandler.play();
  }

  Future<void> pause() async {
    await _audioHandler.pause();
  }

  /// `index` is not shuffled index
  Future<void> seek(Duration position, {int? index}) async {
    await _audioHandler.audioPlayer.seek(position, index: index);
  }

  Future<void> previous([bool force = false]) async {
    if (force) {
      await _audioHandler.skipToPrevious();
    } else {
      await _audioHandler.skipToPreviousUnforced();
    }
  }

  Future<void> next([bool force = false]) async {
    if (force) {
      await _audioHandler.skipToNext();
    } else {
      await _audioHandler.skipToNextUnforced();
    }
  }

  Future<void> add(MusicData song) async {
    if (!song.isInstalled && !(await song.isAudioUrlAvailable())) {
      await song.refreshAudioUrl();
    }
    await _audioHandler.addQueueItem(await song.toMediaItem());
  }

  Future<void> addAll(List<MusicData> songs) async {
    await _audioHandler.addQueueItems(
      await Future.wait(
        songs.map((e) => (MusicData e) async {
              if (!e.isInstalled && !(await e.isAudioUrlAvailable())) {
                await e.refreshAudioUrl();
              }
              return e.toMediaItem();
            }(e)),
      ),
    );
  }

  Future<void> remove(String key) async {
    final int index =
        audioDataManager.playlist.indexWhere((song) => song.key == key);

    // fix index (https://github.com/yuko1101/asterfox/issues/47)
    final int? currentPlayingIndex = audioDataManager.currentIndex;
    final bool isPlaying =
        audioDataManager.playingState == PlayingState.playing;
    final int songsCount = audioDataManager.playlist.length;
    final bool isCertainRepeatMode =
        audioDataManager.repeatState != RepeatState.all;

    if (index == currentPlayingIndex &&
        isPlaying &&
        index == songsCount - 1 &&
        isCertainRepeatMode &&
        songsCount > 1) {
      if (audioDataManager.repeatState == RepeatState.none) pause();
      seek(Duration.zero, index: 0);
    }

    if (index != -1) {
      await _audioHandler.removeQueueItemAt(index);
    }
  }

  Future<void> clear() async {
    await _audioHandler.clear();
  }

  Future<void> move(int currentIndex, int newIndex) async {
    // await _audioHandler.customAction("move", {"oldIndex": currentIndex, "newIndex": newIndex});
    await _audioHandler.move(
      currentIndex,
      newIndex,
      audioStateManager.mainNotifier,
    );
  }

  Future<void> stop() async {
    await _audioHandler.stop();
  }

  Future<void> playback([bool force = false]) async {
    // if current progress is less than 5 sec, skip previous. if not, replay the current song.
    if (audioDataManager.progress.current.inMilliseconds < 5000) {
      // if current index is 0 and repeat mode is none, replay the current song.
      if (audioDataManager.repeatState == RepeatState.none &&
          audioDataManager.currentShuffledIndex == 0) {
        await seek(Duration.zero);
      } else {
        await previous(force);
      }
    } else {
      await seek(Duration.zero);
    }
  }

  final repeatModes = RepeatState.values;

  Future<void> setRepeatMode(RepeatState mode) async {
    await _audioHandler
        .setRepeatMode(repeatStateToAudioServiceRepeatMode(mode));
  }

  Future<void> nextRepeatMode() async {
    final repeatMode = audioDataManager.repeatState;
    final index = repeatModes.indexOf(repeatMode);
    if (index == -1) {
      return;
    }
    final nextIndex = (index + 1) % repeatModes.length;
    await setRepeatMode(repeatModes[nextIndex]);
  }

  Future<void> toggleShuffle() async {
    final enable = !audioDataManager.isShuffled;
    _audioHandler.setShuffleMode(
        enable ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
  }

  Future<void> setSongs(List<MusicData> songs) async {
    await _audioHandler.setSongs(songs);
  }

  /// `index` is not shuffled index.
  Future<void> refreshSongs([int index = -1]) async {
    // if index is -1, refresh all songs
    final currentIndex = audioDataManager.currentIndex;
    final currentPosition = audioDataManager.progress.current;
    final wasPlaying = audioDataManager.playingState == PlayingState.playing;
    if (index == -1) {
      await _audioHandler.setSongs(audioDataManager.playlist);
    } else {
      final MusicData song = audioDataManager.playlist[index];

      // while removing the song, refresh the song.
      final completer = Completer();
      () async {
        await _audioHandler.removeQueueItemAt(index);
        completer.complete();
      }();

      // if removing is not finished, wait for it to finish
      if (!completer.isCompleted) await completer.future;

      await _audioHandler.insertQueueItem(index, await song.toMediaItem());
    }
    await seek(
      currentPosition,
      index: index == -1 || currentIndex == index ? currentIndex : null,
    );
    if (wasPlaying) {
      await play();
    }
  }

  Future<void> setBaseVolume(double volume) async {
    print("setBaseVolume: " + volume.toString());
    baseVolumeNotifier.value = volume;
    DeviceSettingsData.data.set(key: "baseVolume", value: volume);
    await updateVolume();
    await DeviceSettingsData.save();
  }

  Future<void> updateVolume() async {
    final volume = (muteNotifier.value ? 0 : 1) *
        baseVolumeNotifier.value *
        audioDataManager.currentSongVolume;
    if (OS.getOS() == OSType.android) {
      _audioHandler.androidEnhancer
          .setTargetGain(max(MathUtils.log(volume, VolumeWidget.base), 0));
    }
    await _audioHandler.audioPlayer.setVolume(volume);
  }

  Future<void> setMute(bool mute) async {
    muteNotifier.value = mute;
    await updateVolume();
  }

  SessionAudioHandler get audioHandler => _audioHandler;
  AudioSession get audioSession => _audioSession;
}
