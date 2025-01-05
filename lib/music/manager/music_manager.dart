import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../data/device_settings_data.dart';
import '../../data/local_musics_data.dart';
import '../../data/settings_data.dart';
import '../../utils/os.dart';
import '../../widget/music_widgets/repeat_button.dart';
import '../music_data/music_data.dart';
import 'audio_data_manager.dart';
import 'audio_handler.dart';
import 'audio_player.dart';
import 'music_listener.dart';
import 'notifiers/audio_state_notifier.dart';

final bool canNotify = OS.isWeb || OS.isAndroid || OS.isIOS || OS.isMacOS;

class MusicManager {
  MusicManager(this.showNotification);
  final bool showNotification;

  late final AudioPlayer _audioPlayer = AudioPlayer(this);
  late final SessionAudioHandler _audioHandler;
  late final AudioSession _audioSession;

  // notifiers
  final audioStateManager = AudioStateManager();

  final muteNotifier = ValueNotifier<bool>(false);
  final baseVolumeNotifier = ValueNotifier<double>(1.0);

  Future<void> init() async {
    final bool handleInterruptions =
        !SettingsData.getValue(key: "disableInterruptions");
    if (canNotify && showNotification) {
      _audioHandler = await AudioService.init(
          builder: () =>
              SessionAudioHandler(_audioPlayer, true, handleInterruptions),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'net.asterfox.app.channel.audio',
            androidNotificationChannelName: 'Asterfox Music',
            androidStopForegroundOnPause: true,
            androidShowNotificationBadge: true,
          ));
    } else {
      _audioHandler =
          SessionAudioHandler(_audioPlayer, false, handleInterruptions);
    }
    audioStateManager.init();
    MusicListener(this, _audioPlayer).init();
  }

  MainAudioStateNotifier get notifier => audioStateManager.mainNotifier;
  AudioState get state => notifier.value;

  Future<void> play() async {
    await _audioHandler.play();
  }

  Future<void> pause() async {
    await _audioHandler.pause();
  }

  /// `index` is not shuffled index
  Future<void> seek(Duration position, {int? index}) async {
    await _audioHandler.seek(position, index: index);
  }

  Future<void> previous() async {
    await _audioHandler.skipToPrevious();
  }

  Future<void> next() async {
    await _audioHandler.skipToNext();
  }

  Future<void> add(MusicData<CachingEnabled> song) async {
    if (!song.isInstalled && !await song.isAudioUrlAvailable()) {
      await song.refreshAudioUrl();
    }
    await _audioHandler.addQueueItem(await song.toMediaItem());
  }

  Future<void> addAll(List<MusicData<CachingEnabled>> songs) async {
    await _audioHandler.addQueueItems(
      await Future.wait(
        songs.map((e) => (MusicData<CachingEnabled> e) async {
              if (!e.isInstalled && !await e.isAudioUrlAvailable()) {
                await e.refreshAudioUrl();
              }
              return e.toMediaItem();
            }(e)),
      ),
    );
  }

  // TODO: not to call "remove" or "move" method (reordering method) multiple times at the same time
  Future<void> remove(String key) async {
    final int index = state.playlist.indexWhere(
        (song) => (song as MusicData<CachingEnabled>).caching.key == key);

    if (index == -1) return;

    await _audioHandler.removeQueueItemAt(index);
  }

  Future<void> move(int currentIndex, int newIndex) async {
    // await _audioHandler.customAction("move", {"oldIndex": currentIndex, "newIndex": newIndex});
    await _audioHandler.move(currentIndex, newIndex);
  }

  Future<void> stop() async {
    await _audioHandler.stop();
  }

  Future<void> playback() async {
    // if current progress is less than 5 sec, skip previous. if not, replay the current song.
    if (state.progress.position.inMilliseconds < 5000) {
      // if current index is 0 and repeat mode is none, replay the current song.
      if (state.repeatState == RepeatState.none && state.currentIndex == 0) {
        await seek(Duration.zero);
      } else {
        await previous();
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
    final repeatMode = state.repeatState;
    final index = repeatModes.indexOf(repeatMode);
    if (index == -1) {
      return;
    }
    final nextIndex = (index + 1) % repeatModes.length;
    await setRepeatMode(repeatModes[nextIndex]);
  }

  Future<void> toggleShuffle() async {
    final enable = !state.shuffled;
    _audioHandler.setShuffleMode(
        enable ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
  }

  Future<void> setSongs(List<MusicData<CachingEnabled>> songs) async {
    await _audioHandler.setSongs(songs);
  }

  /// `index` is not shuffled index.
  Future<void> refreshSongs([int index = -1]) async {
    // if index is -1, refresh all songs
    final currentIndex = state.currentIndex;
    final currentPosition = state.progress.position;
    final wasPlaying = state.playingState == PlayingState.playing;
    if (index == -1) {
      await _audioHandler
          .setSongs(state.playlist.cast<MusicData<CachingEnabled>>());
    } else {
      final song = state.playlist[index] as MusicData<CachingEnabled>;

      await _audioHandler.removeQueueItemAt(index);
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
    baseVolumeNotifier.value = volume;
    DeviceSettingsData.data.set(key: "baseVolume", value: volume);
    await updateVolume();
    await DeviceSettingsData.save();
  }

  Future<void> updateVolume() async {
    final volume = (muteNotifier.value ? 0 : 1) *
        baseVolumeNotifier.value *
        state.currentSongVolume;
    await _audioPlayer.setVolume(volume);
  }

  Future<void> setMute(bool mute) async {
    muteNotifier.value = mute;
    await updateVolume();
  }

  SessionAudioHandler get audioHandler => _audioHandler;
  AudioSession get audioSession => _audioSession;
}
