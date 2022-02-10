import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/manager/music_listener.dart';
import 'package:asterfox/music/manager/windows/windows_audio_handler.dart';
import 'package:asterfox/music/manager/windows/windows_music_listener.dart';
import 'package:asterfox/notifiers/progress_notifier.dart';
import 'package:asterfox/util/os.dart';
import 'package:asterfox/widget/music_widgets/audio_progress_bar.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_handler.dart';

class MusicManager {
  late final AudioHandler _audioHandler;

  bool windowsMode = OS.getOS() == OSType.windows;

  late final WindowsAudioHandler _windowsAudioHandler;

  
  //notifiers
  final progressNotifier = ProgressNotifier();
  final playlistNotifier = ValueNotifier<List<AudioBase>>([]);
  final currentSongNotifier = ValueNotifier<AudioBase?>(null);
  final playingNotifier = ValueNotifier<PlayingState>(PlayingState.disabled);
  final currentIndexNotifier = ValueNotifier<int?>(null);

  final hasNextNotifier = ValueNotifier<bool>(false);



  Future<void> init() async {
    if (!windowsMode) {
      _audioHandler = await AudioService.init(
          builder: () => AudioPlayerHandler(),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'net.asterium.asterfox.channel.audio',
            androidNotificationChannelName: 'Asterfox Music',
            androidNotificationOngoing: true,
          )
      );
      MusicListener(this, _audioHandler).init();
    } else {
      _windowsAudioHandler = WindowsAudioHandler();
      WindowsMusicListener(this, _windowsAudioHandler).init();
    }
  }

  Future<void> play() async {
    print("Played a playlist: " + playlistNotifier.value.length.toString() + " songs");
    windowsMode ? await _windowsAudioHandler.play() : await _audioHandler.play();
  }
  Future<void> pause() async {
    windowsMode ? await _windowsAudioHandler.pause() : await _audioHandler.pause();
  }

  void seek(Duration position) {
    windowsMode ? _windowsAudioHandler.seek(position) : _audioHandler.seek(position);
  }
  Future<void> seekSync(Duration position) async {
    windowsMode ? await _windowsAudioHandler.seek(position) : await _audioHandler.seek(position);
  }

  Future<void> previous() async {
    windowsMode ? await _windowsAudioHandler.skipToPrevious() : await _audioHandler.skipToPrevious();
  }
  Future<void> next() async {
    windowsMode ? await _windowsAudioHandler.skipToNext() : await _audioHandler.skipToNext();
  }

  Future<void> add(AudioBase song) async {
    windowsMode ? await _windowsAudioHandler.addQueueItem(song.getMediaItem()) : await _audioHandler.addQueueItem(song.getMediaItem());

  }
  Future<void> addAll(List<AudioBase> songs) async {
    windowsMode ? await _windowsAudioHandler.addQueueItems(songs.map((e) => e.getMediaItem()).toList())
        : await _audioHandler.addQueueItems(songs.map((e) => e.getMediaItem()).toList());
  }
  
  Future<void> move(int currentIndex, int newIndex) async {
    windowsMode ? await _windowsAudioHandler.move(currentIndex, newIndex)
        : await _audioHandler.customAction("move", {"oldIndex": currentIndex, "newIndex": newIndex});
  }

  void stop() {
    windowsMode ? _windowsAudioHandler.stop() : _audioHandler.stop();
  }

  // if position is less than 2 sec, skip previous. if not, replay the current song
  Future<void> playback() async {
    if (progressNotifier.value.current.inMilliseconds < 5000) {
      await previous();
    } else {
      await seekSync(Duration.zero);
    }
  }
}