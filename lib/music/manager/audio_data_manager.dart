import 'dart:math';

import 'package:media_kit/media_kit.dart';

import '../../widget/music_widgets/audio_progress_bar.dart';
import '../../widget/music_widgets/repeat_button.dart';
import '../music_data/music_data.dart';
import 'audio_player.dart';

class AudioDataManager extends AudioDataContainer {
  AudioDataManager(this.audioPlayer);
  final AudioPlayer audioPlayer;

  @override
  List<Media> get $medias => audioPlayer.state.playlist.medias;
  @override
  int? get $currentIndex => audioPlayer.state.playlist.index;
  @override
  bool get shuffled => audioPlayer.shuffled;
  @override
  bool get $playing => audioPlayer.state.playing;
  @override
  PlaylistMode get $playlistMode => audioPlayer.state.playlistMode;
  @override
  double get $volume => audioPlayer.state.volume;

  ProgressBarState get progress => AudioDataManager.getProgress(
        audioPlayer.state.position,
        audioPlayer.state.buffer,
        audioPlayer.state.duration,
      );

  static List<MusicData> getPlaylist(List<Media> medias) {
    final playlist = medias;
    return playlist.map((media) => media.toMusicData()).toList();
  }

  static List<MusicData> getShuffledPlaylist(
      List<Media> media, bool shuffled, List<int>? indices) {
    final playlist = getPlaylist(media);
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

  static int? getCurrentIndex(int? index, List<Media> medias) {
    final queue = medias;
    if (queue.isEmpty) return null;
    if (queue.isNotEmpty && index == null) return 0;
    if (index == null) return null;
    return min(index, queue.length - 1);
  }

  static int? getCurrentShuffledIndex(
      int? index, List<Media> medias, bool shuffled, List<int>? indices) {
    final currentIndex = getCurrentIndex(index, medias);
    if (!shuffled) return currentIndex;
    if (indices == null) return currentIndex;
    if (currentIndex == null) return null;
    return !indices.contains(currentIndex)
        ? null
        : indices.indexOf(currentIndex);
  }

  static MusicData? getCurrentSong(int? index, List<Media> medias) {
    if (index == null) return null;
    final playlist = getPlaylist(medias);
    if (index >= playlist.length || index < 0) return null;
    return playlist[index];
  }

  static PlayingState getPlayingState(bool playing, List<Media> medias) {
    // TODO: implement PlayingState.loading
    if (medias.isEmpty) {
      return PlayingState.disabled;
    } else if (!playing) {
      return PlayingState.paused;
    } else {
      return PlayingState.playing;
    }
  }

  static ProgressBarState getProgress(
      Duration current, Duration buffered, Duration total) {
    return ProgressBarState(current: current, buffered: buffered, total: total);
  }

  static RepeatState getRepeatState(PlaylistMode playlistMode) {
    return playlistModeToRepeatState(playlistMode);
  }

  static bool getHasNext(
      int? index, List<Media> medias, PlaylistMode playlistMode) {
    final max = medias.length;
    final current = getCurrentIndex(index, medias);
    final repeat = getRepeatState(playlistMode);
    if (max == 0) {
      return false;
    } else if (current == null) {
      return false;
    } else if ([RepeatState.one, RepeatState.all].contains(repeat)) {
      return true;
    }
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
  List<Media> get $medias;
  int? get $currentIndex;
  bool get shuffled;
  bool get $playing;
  PlaylistMode get $playlistMode;
  double get $volume;

  List<MusicData> get playlist => AudioDataManager.getPlaylist($medias);
  int? get currentIndex =>
      AudioDataManager.getCurrentIndex($currentIndex, $medias);
  MusicData? get currentSong =>
      AudioDataManager.getCurrentSong($currentIndex, $medias);
  PlayingState get playingState =>
      AudioDataManager.getPlayingState($playing, $medias);
  RepeatState get repeatState => AudioDataManager.getRepeatState($playlistMode);
  bool get isShuffled => shuffled;
  bool get hasNext =>
      AudioDataManager.getHasNext($currentIndex, $medias, $playlistMode);
  double get currentSongVolume => currentSong?.volume ?? 1.0;
  double get volume => $volume;
}

enum PlayingState { paused, playing, loading, disabled }
