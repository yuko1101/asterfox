import 'dart:math';

import 'package:just_audio/just_audio.dart';

import '../../widget/music_widgets/audio_progress_bar.dart';
import '../../widget/music_widgets/repeat_button.dart';
import '../audio_source/music_data.dart';

class AudioDataManager extends AudioDataContainer {
  AudioDataManager(this.audioPlayer);
  final AudioPlayer audioPlayer;

  @override
  List<IndexedAudioSource>? get $sequence => audioPlayer.sequence;
  @override
  int? get $currentIndex => audioPlayer.currentIndex;
  @override
  bool get $shuffleMode => audioPlayer.shuffleModeEnabled;
  @override
  List<int>? get $shuffleIndices => audioPlayer.shuffleIndices;
  @override
  PlayerState get $playerState => audioPlayer.playerState;
  @override
  LoopMode get $loopMode => audioPlayer.loopMode;
  @override
  double get $volume => audioPlayer.volume;

  ProgressBarState get progress => AudioDataManager.getProgress(
        audioPlayer.position,
        audioPlayer.bufferedPosition,
        audioPlayer.duration ?? Duration.zero,
      );

  static List<MusicData> getPlaylist(List<IndexedAudioSource>? sequence) {
    final playlist = sequence ?? [];
    return playlist.map((audioSource) => audioSource.toMusicData()).toList();
  }

  static List<MusicData> getShuffledPlaylist(
      List<IndexedAudioSource>? sequence, bool shuffled, List<int>? indices) {
    final playlist = getPlaylist(sequence);
    if (!shuffled) {
      return playlist;
    } else {
      if (indices == null) {
        return playlist;
      }
      // print('shuffledPlaylist: $indices, ${indices.map((index) => index >= playlist.length ? null : playlist[index].title)}');
      // print("shuffled: ${indices.map((index) => index >= playlist.length ? null : playlist[index].title).where((element) => element != null).map((e) => e as String).toList()}");

      // avoid out of range error on delete song (maybe the delay in the shuffled indices causes the error)
      return indices
          .map((index) => index >= playlist.length ? null : playlist[index])
          .where((element) => element != null)
          .map((e) => e as MusicData)
          .toList();
    }
  }

  static int? getCurrentIndex(int? index, List<IndexedAudioSource>? sequence) {
    final queue = sequence ?? [];
    if (queue.isEmpty) return null;
    if (queue.isNotEmpty && index == null) return 0;
    if (index == null) return null;
    return min(index, queue.length - 1);
  }

  static int? getCurrentShuffledIndex(int? index,
      List<IndexedAudioSource>? sequence, bool shuffled, List<int>? indices) {
    final currentIndex = getCurrentIndex(index, sequence);
    if (!shuffled) return currentIndex;
    if (indices == null) return currentIndex;
    if (currentIndex == null) return null;
    return !indices.contains(currentIndex)
        ? null
        : indices.indexOf(currentIndex);
  }

  static MusicData? getCurrentSong(
      int? index, List<IndexedAudioSource>? sequence) {
    if (index == null) return null;
    final playlist = getPlaylist(sequence);
    if (index >= playlist.length || index < 0) return null;
    return playlist[index];
  }

  static PlayingState getPlayingState(
      PlayerState playerState, List<IndexedAudioSource>? sequence) {
    final isPlaying = playerState.playing;
    final processingState = playerState.processingState;
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      return PlayingState.loading;
    } else if (!isPlaying) {
      if ((sequence ?? []).isEmpty) {
        return PlayingState.disabled;
      } else {
        return PlayingState.paused;
      }
    } else if (processingState != ProcessingState.completed) {
      return PlayingState.playing;
    } else {
      return PlayingState.unknown;
    }
  }

  static ProgressBarState getProgress(
      Duration current, Duration buffered, Duration total) {
    return ProgressBarState(current: current, buffered: buffered, total: total);
  }

  static RepeatState getRepeatState(LoopMode loopMode) {
    return loopModeToRepeatState(loopMode);
  }

  static bool getHasNext(int? index, List<IndexedAudioSource>? sequence,
      LoopMode loopMode, bool shuffled, List<int>? indices) {
    final max = sequence?.length ?? 0;
    final current = getCurrentShuffledIndex(index, sequence, shuffled, indices);
    final repeat = getRepeatState(loopMode);
    if (max == 0) {
      return false;
    } else if (current == null) {
      return false;
    } else if ([RepeatState.one, RepeatState.all].contains(repeat)) {
      return true;
    }
    // print('hasNext: $current, $max, $indices, ${getCurrentIndex(index, sequence)}');
    return current < max - 1;
  }

  static int shuffledIndexToNormalIndex(
      int index, bool shuffled, List<int>? indices) {
    // if not shuffled, return index
    if (indices == null || !shuffled) return index;

    print("shuffled: $index to normal: ${indices[index]} by indices: $indices");
    return indices[index];
  }

  static int normalIndexToShuffledIndex(
      int index, bool shuffled, List<int>? indices) {
    // if not shuffled, return index
    if (indices == null || !shuffled) return index;

    print(
        "normal: $index to shuffled: ${indices.indexOf(index)} by indices: $indices");
    return indices.indexOf(index);
  }
}

abstract class AudioDataContainer {
  List<IndexedAudioSource>? get $sequence;
  int? get $currentIndex;
  bool get $shuffleMode;
  List<int>? get $shuffleIndices;
  PlayerState get $playerState;
  LoopMode get $loopMode;
  double get $volume;

  List<MusicData> get playlist => AudioDataManager.getPlaylist($sequence);
  List<MusicData> get shuffledPlaylist => AudioDataManager.getShuffledPlaylist(
      $sequence, $shuffleMode, $shuffleIndices);
  int? get currentIndex =>
      AudioDataManager.getCurrentIndex($currentIndex, $sequence);
  int? get currentShuffledIndex => AudioDataManager.getCurrentShuffledIndex(
      $currentIndex, $sequence, $shuffleMode, $shuffleIndices);
  MusicData? get currentSong =>
      AudioDataManager.getCurrentSong($currentIndex, $sequence);
  PlayingState get playingState =>
      AudioDataManager.getPlayingState($playerState, $sequence);
  RepeatState get repeatState => AudioDataManager.getRepeatState($loopMode);
  bool get isShuffled => $shuffleMode;
  bool get hasNext => AudioDataManager.getHasNext(
      $currentIndex, $sequence, $loopMode, $shuffleMode, $shuffleIndices);
  double get currentSongVolume => currentSong?.volume ?? 1.0;
  double get volume => $volume;

  List<int>? get shuffledIndices => $shuffleIndices;

  int getShuffledIndex(int normalIndex) =>
      AudioDataManager.normalIndexToShuffledIndex(
          normalIndex, isShuffled, shuffledIndices);
  int getNormalIndex(int shuffledIndex) =>
      AudioDataManager.shuffledIndexToNormalIndex(
          shuffledIndex, isShuffled, shuffledIndices);
}

enum PlayingState { paused, playing, loading, disabled, unknown }
