import 'dart:async';

import 'package:asterfox/config/settings_data.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/manager/music_listener.dart';
import 'package:asterfox/music/manager/notifiers/nullable_integer_notifier.dart';
import 'package:asterfox/music/manager/notifiers/playlist_notifier.dart';
import 'package:asterfox/music/manager/notifiers/song_notifier.dart';
import 'package:asterfox/util/os.dart';
import 'package:asterfox/widget/music_widgets/audio_progress_bar.dart';
import 'package:asterfox/widget/music_widgets/repeat_button.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';

import 'audio_data_manager.dart';
import 'audio_handler.dart';

class MusicManager {

  MusicManager(this.showNotification) {
    useAudioSession = SettingsData.getValue(key: "useAudioSession") as bool;
  }
  final bool showNotification;
  late final bool useAudioSession;

  late final SessionAudioHandler _audioHandler;
  late final AudioSession _audioSession;

  static bool windowsMode = OS.getOS() == OSType.windows;
  
  //notifiers
  final progressNotifier = ProgressNotifier();
  final playlistNotifier = PlaylistNotifier([]);
  final shuffledPlaylistNotifier = PlaylistNotifier([]);
  final currentSongNotifier = SongNotifier(null);
  final playingStateNotifier = ValueNotifier<PlayingState>(PlayingState.disabled);
  final currentIndexNotifier = NullableIntegerNotifier(null); // シャッフルない状態でのindex
  final currentShuffledIndexNotifier = NullableIntegerNotifier(null); // シャッフル対応index

  final hasNextNotifier = ValueNotifier<bool>(false);
  final repeatModeNotifier = ValueNotifier<RepeatState>(RepeatState.none);
  final shuffleModeNotifier = ValueNotifier<bool>(false);



  Future<void> init() async {
    if (!windowsMode && showNotification) {
      _audioHandler = await AudioService.init(
          builder: () => SessionAudioHandler(true),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'net.asterfox.app.channel.audio',
            androidNotificationChannelName: 'Asterfox Music',
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: true,
            androidShowNotificationBadge: true,
          )
      );
      if (useAudioSession) {
        _audioSession = await AudioSession.instance;
        await _audioSession.configure(const AudioSessionConfiguration.music());
        if (await _audioSession.setActive(true)) {
          print('AudioSession activated');
        } else {
          print('AudioSession activation failed');
        }
      }
    } else {
      print("windowsMode");
      _audioHandler = SessionAudioHandler(false);
    }
    MusicListener(this, _audioHandler).init();
  }

  Future<void> play() async {
    print("Played a playlist: " + playlistNotifier.value.length.toString() + " songs");
    await _audioHandler.play();
  }
  Future<void> pause() async {
    await _audioHandler.pause();
  }

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

  Future<void> add(AudioBase song) async {
    await _audioHandler.addQueueItem(song.getMediaItem());

  }
  Future<void> addAll(List<AudioBase> songs) async {
    await _audioHandler.addQueueItems(songs.map((e) => e.getMediaItem()).toList());
  }

  Future<void> remove(String key) async {
    final int index = playlistNotifier.value.indexWhere((song) => song.key == key);
    if (index != -1) {
      await _audioHandler.removeQueueItemAt(index);
    }
  }

  Future<void> clear() async {
    await _audioHandler.clear();
  }
  
  Future<void> move(int currentIndex, int newIndex) async {
   // await _audioHandler.customAction("move", {"oldIndex": currentIndex, "newIndex": newIndex});
    await _audioHandler.move(currentIndex, newIndex);
  }

  void stop() {
    _audioHandler.stop();
  }

  Future<void> playback([bool force = false]) async {
    // if current progress is less than 5 sec, skip previous. if not, replay the current song.
    if (progressNotifier.value.current.inMilliseconds < 5000) {
      // if current index is 0 and repeat mode is none, replay the current song.
      if (repeatModeNotifier.value == RepeatState.none && currentIndexNotifier.value == 0) {
        await seek(Duration.zero);
      } else {
        await previous(force);
      }
    } else {
      await seek(Duration.zero);
    }
  }

  final repeatModes = [
    RepeatState.none,
    RepeatState.all,
    RepeatState.one,
  ];

  Future<void> setRepeatMode(RepeatState mode) async {
    await _audioHandler.setRepeatMode(repeatStateToAudioServiceRepeatMode(mode));
  }

  Future<void> nextRepeatMode() async {
    final repeatMode = repeatModeNotifier.value;
    final index = repeatModes.indexOf(repeatMode);
    if (index == -1) {
      return;
    }
    final nextIndex = (index + 1) % repeatModes.length;
    await setRepeatMode(repeatModes[nextIndex]);
  }

  Future<void> toggleShuffle() async {
    final enable = !shuffleModeNotifier.value;
    _audioHandler.setShuffleMode(enable ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
    shuffleModeNotifier.value = enable;
  }

  Future<void> refreshSongs([int index = -1]) async {
    // if index is -1, refresh all songs
    final currentIndex = currentIndexNotifier.value;
    final currentPosition = progressNotifier.value.current;
    final wasPlaying = playingStateNotifier.value == PlayingState.playing;
    if (index == -1) {

      final List<AudioBase> songs = playlistNotifier.value;

      // while clearing the playlist, refresh the songs.
      final completer = Completer();
      (() async {
        await clear();
        completer.complete();
      })();

      // refresh the songs
      final List<AudioBase> refreshed = await Future.wait(songs.map((song) async {
        return await song.refresh();
      }));

      // if clearing is not finished, wait for it to finish
      if (!completer.isCompleted) await completer.future;

      await addAll(refreshed);

      // TODO: fix the index out of range issue

    } else {
      final AudioBase song = playlistNotifier.value[index];

      // while removing the song, refresh the song.
      final completer = Completer();
      (() async {
        await _audioHandler.removeQueueItemAt(index);
        completer.complete();
      })();

      // refresh the song
      final AudioBase refresh = await song.refresh();

      // if removing is not finished, wait for it to finish
      if (!completer.isCompleted) await completer.future;

      await _audioHandler.insertQueueItem(index, refresh.getMediaItem());
    }
    await seek(currentPosition, index: index == -1 || currentIndex == index ? currentIndex : null);
    if (wasPlaying) {
      await play();
    }
  }


  int? getShuffledIndex() {
    final int index = currentSongNotifier.value != null ? playlistNotifier.value.indexWhere((song) => song.key! == currentSongNotifier.value!.key!) : -1;
    return (index == -1 ? null : index);

  }

  SessionAudioHandler get audioHandler => _audioHandler;
  AudioSession get audioSession => _audioSession;
}