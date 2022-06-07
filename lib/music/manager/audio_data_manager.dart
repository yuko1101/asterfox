import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/widget/music_widgets/audio_progress_bar.dart';
import 'package:asterfox/widget/music_widgets/repeat_button.dart';
import 'package:just_audio/just_audio.dart';

class AudioDataManager {
  AudioDataManager(this.audioPlayer);
  final AudioPlayer audioPlayer;

  List<MusicData> get playlist => AudioDataManager.getPlaylist(audioPlayer.sequence);
  List<MusicData> get shuffledPlaylist => AudioDataManager.getShuffledPlaylist(audioPlayer.sequence, audioPlayer.shuffleModeEnabled, audioPlayer.shuffleIndices);
  int? get currentIndex => getCurrentIndex(audioPlayer.currentIndex, audioPlayer.sequence);
  int? get currentShuffledIndex => getCurrentShuffledIndex(audioPlayer.currentIndex, audioPlayer.sequence, audioPlayer.shuffleModeEnabled, audioPlayer.shuffleIndices);
  MusicData? get currentSong => getCurrentSong(audioPlayer.currentIndex, audioPlayer.sequence);
  PlayingState get playingState => getPlayingState(audioPlayer.playerState, audioPlayer.sequence);
  ProgressBarState get progress => getProgress(audioPlayer.position, audioPlayer.bufferedPosition, audioPlayer.duration ?? Duration.zero);
  RepeatState get repeatState => getRepeatState(audioPlayer.loopMode);
  bool get shuffle => audioPlayer.shuffleModeEnabled;
  bool get hasNext => getHasNext(audioPlayer.currentIndex, audioPlayer.sequence, audioPlayer.loopMode, audioPlayer.shuffleModeEnabled, audioPlayer.shuffleIndices);



  static List<MusicData> getPlaylist(List<IndexedAudioSource>? sequence) {
    final playlist = sequence ?? [];
    return playlist.map((audioSource) => audioSource.toMusicData()).toList();
  }

  static List<MusicData> getShuffledPlaylist(List<IndexedAudioSource>? sequence, bool shuffle, List<int>? indices) {
    final playlist = getPlaylist(sequence);
    if (!shuffle) {
      return playlist;
    } else {
      if (indices == null) {
        return playlist;
      }
      // print('shuffledPlaylist: $indices, ${indices.map((index) => index >= playlist.length ? null : playlist[index].title)}');
      // print("shuffled: ${indices.map((index) => index >= playlist.length ? null : playlist[index].title).where((element) => element != null).map((e) => e as String).toList()}");

      // avoid out of range error on delete song (the delay in the shuffled indices causes the error)
      return indices.map((index) => index >= playlist.length ? null : playlist[index]).where((element) => element != null).map((e) => e as MusicData).toList();
    }
  }

  static int? getCurrentIndex(int? index, List<IndexedAudioSource>? sequence) {
    if ((sequence ?? []).isEmpty) return null;
    return index;
  }

  static int? getCurrentShuffledIndex(int? index, List<IndexedAudioSource>? sequence, bool shuffle, List<int>? indices) {
    final currentIndex = getCurrentIndex(index, sequence);
    if (!shuffle) return currentIndex;
    if (indices == null) return currentIndex;
    if (currentIndex == null) return null;
    return !indices.contains(currentIndex) ? null : indices.indexOf(currentIndex);
  }

  static MusicData? getCurrentSong(int? index, List<IndexedAudioSource>? sequence) {
    if (index == null) return null;
    final playlist = getPlaylist(sequence);
    if (index >= playlist.length || index < 0) return null;
    return playlist[index];
  }

  static PlayingState getPlayingState(PlayerState playerState, List<IndexedAudioSource>? sequence) {
    final isPlaying = playerState.playing;
    final processingState = playerState.processingState;
    if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
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

  static ProgressBarState getProgress(Duration current, Duration buffered, Duration total) {
    return ProgressBarState(current: current, buffered: buffered, total: total);
  }

  static RepeatState getRepeatState(LoopMode loopMode) {
    return loopModeToRepeatState(loopMode);
  }

  // TODO: support shuffle mode
  static bool getHasNext(int? index, List<IndexedAudioSource>? sequence, LoopMode loopMode, bool shuffle, List<int>? indices) {
    final max = sequence?.length ?? 0;
    final current = getCurrentShuffledIndex(index, sequence, shuffle, indices);
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

}

enum PlayingState {
  paused,
  playing,
  loading,
  disabled,
  unknown
}