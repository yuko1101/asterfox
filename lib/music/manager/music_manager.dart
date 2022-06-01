import 'dart:async';

import 'package:asterfox/config/settings_data.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/manager/music_listener.dart';
import 'package:asterfox/music/manager/notifiers/data_notifier.dart';
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
  late final AudioDataManager audioDataManager;

  static bool windowsMode = OS.getOS() == OSType.windows;
  
  //notifiers
  final progressNotifier = ProgressNotifier();
  final playlistNotifier = PlaylistNotifier([]);
  final shuffledPlaylistNotifier = PlaylistNotifier([]);
  final currentSongNotifier = SongNotifier(null);
  final playingStateNotifier = ValueNotifier<PlayingState>(PlayingState.disabled);
  final currentIndexNotifier = DataNotifier<int?>(null); // シャッフルない状態でのindex
  final currentShuffledIndexNotifier = DataNotifier<int?>(null); // シャッフル対応index

  final hasNextNotifier = ValueNotifier<bool>(false);
  final repeatModeNotifier = ValueNotifier<RepeatState>(RepeatState.none);
  final shuffleModeNotifier = DataNotifier<bool>(false);



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
    audioDataManager = AudioDataManager(_audioHandler.audioPlayer);
  }

  Future<void> play() async {
    print("Played a playlist: " + audioDataManager.playlist.length.toString() + " songs");
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
    await _audioHandler.addQueueItem(song.toMediaItem());

  }
  Future<void> addAll(List<MusicData> songs) async {
    await _audioHandler.addQueueItems(songs.map((e) => e.toMediaItem()).toList());
  }

  Future<void> remove(String key) async {
    final int index = audioDataManager.playlist.indexWhere((song) => song.key == key);
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
    if (audioDataManager.progress.current.inMilliseconds < 5000) {
      // if current index is 0 and repeat mode is none, replay the current song.
      if (audioDataManager.repeatState == RepeatState.none && audioDataManager.currentShuffledIndex == 0) {
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
    final repeatMode = audioDataManager.repeatState;
    final index = repeatModes.indexOf(repeatMode);
    if (index == -1) {
      return;
    }
    final nextIndex = (index + 1) % repeatModes.length;
    await setRepeatMode(repeatModes[nextIndex]);
  }

  Future<void> toggleShuffle() async {
    final enable = !audioDataManager.shuffle;
    _audioHandler.setShuffleMode(enable ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
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
      (() async {
        await _audioHandler.removeQueueItemAt(index);
        completer.complete();
      })();

      // if removing is not finished, wait for it to finish
      if (!completer.isCompleted) await completer.future;

      await _audioHandler.insertQueueItem(index, song.toMediaItem());
    }
    await seek(currentPosition, index: index == -1 || currentIndex == index ? currentIndex : null);
    if (wasPlaying) {
      await play();
    }
  }

  SessionAudioHandler get audioHandler => _audioHandler;
  AudioSession get audioSession => _audioSession;
}