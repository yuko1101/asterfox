import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/manager/music_listener.dart';
import 'package:asterfox/util/os.dart';
import 'package:asterfox/widget/music_widgets/audio_progress_bar.dart';
import 'package:asterfox/widget/music_widgets/repeat_button.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'audio_handler.dart';

class MusicManager {

  late final AudioPlayerHandler _audioHandler;

  static bool windowsMode = OS.getOS() == OSType.windows;
  
  //notifiers
  final progressNotifier = ProgressNotifier();
  final playlistNotifier = ValueNotifier<List<AudioBase>>([]);
  final currentSongNotifier = ValueNotifier<AudioBase?>(null);
  final playingNotifier = ValueNotifier<PlayingState>(PlayingState.disabled);
  final currentIndexNotifier = ValueNotifier<int?>(null); // シャッフルない状態でのindex
  final currentShuffledIndexNotifier = ValueNotifier<int?>(null); // シャッフル対応index

  final hasNextNotifier = ValueNotifier<bool>(false);
  final repeatModeNotifier = ValueNotifier<RepeatState>(RepeatState.none);
  final shuffleModeNotifier = ValueNotifier<bool>(false);



  Future<void> init() async {
    _audioHandler = AudioPlayerHandler();
    MusicListener(this, _audioHandler).init();
    if (!windowsMode) {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'net.asterfox.app.channel.audio',
        androidNotificationChannelName: 'Asterfox Music',
        androidNotificationOngoing: true,
      );
    }
  }

  Future<void> play() async {
    print("Played a playlist: " + playlistNotifier.value.length.toString() + " songs");
    await _audioHandler.play();
  }
  Future<void> pause() async {
    await _audioHandler.pause();
  }

  void seek(Duration position) {
    _audioHandler.seek(position);
  }
  Future<void> seekSync(Duration position) async {
    await _audioHandler.seek(position);
  }

  Future<void> previous() async {
    await _audioHandler.skipToPrevious();
  }
  Future<void> next() async {
    await _audioHandler.skipToNext();
  }

  Future<void> add(AudioBase song) async {
    await _audioHandler.addQueueItem(song.getAudioSource());

  }
  Future<void> addAll(List<AudioBase> songs) async {
    await _audioHandler.addQueueItems(songs.map((e) => e.getAudioSource()).toList());
  }

  Future<void> remove(String key) async {
    final int index = playlistNotifier.value.indexWhere((song) => song.key == key);
    if (index != -1) {
      await _audioHandler.removeQueueItemAt(index);
    }
  }
  
  Future<void> move(int currentIndex, int newIndex) async {
    await _audioHandler.move(currentIndex, newIndex);
  }

  void stop() {
    _audioHandler.stop();
  }

  // if position is less than 2 sec, skip previous. if not, replay the current song
  Future<void> playback() async {
    if (progressNotifier.value.current.inMilliseconds < 5000) {
      await previous();
    } else {
      await seekSync(Duration.zero);
    }
  }

  final repeatModes = [
    RepeatState.none,
    RepeatState.all,
    RepeatState.one,
  ];
  Future<void> nextRepeatMode() async {
    final repeatMode = repeatModeNotifier.value;
    final index = repeatModes.indexOf(repeatMode);
    if (index == -1) {
      return;
    }
    final nextIndex = (index + 1) % repeatModes.length;
    _audioHandler.setRepeatMode(repeatStateToLoopMode(repeatModes[nextIndex]));
  }

  Future<void> toggleShuffle() async {
    final enable = !shuffleModeNotifier.value;
    _audioHandler.setShuffleMode(enable);
    shuffleModeNotifier.value = enable;
  }

  int? getShuffledIndex() {
    final int index = currentSongNotifier.value != null ? playlistNotifier.value.indexWhere((song) => song.key! == currentSongNotifier.value!.key!) : -1;
    return (index == -1 ? null : index);

  }
}