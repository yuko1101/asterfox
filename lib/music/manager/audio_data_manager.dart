import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';

import '../../widget/music_widgets/repeat_button.dart';
import '../music_data/music_data.dart';

class AudioState extends AudioDataContainer {
  AudioState({
    required this.$medias,
    required this.$currentIndex,
    required this.$shuffled,
    required this.$playing,
    required this.$playlistMode,
    required this.$volume,
    required this.$buffer,
    required this.$position,
    required this.$duration,
    required this.$rate,
    required this.$buffering,
    required this.$completed,
  });

  @override
  final List<Media> $medias;
  @override
  final int $currentIndex;
  @override
  final bool $shuffled;
  @override
  final bool $playing;
  @override
  final PlaylistMode $playlistMode;
  @override
  final double $volume;
  @override
  final Duration $buffer;
  @override
  final Duration $position;
  @override
  final Duration $duration;
  @override
  final double $rate;
  @override
  final bool $buffering;
  @override
  final bool $completed;

  AudioState copyWith(Map<AudioRawData, dynamic> map) {
    dynamic getData(AudioRawData dataType) =>
        map.containsKey(dataType) ? map[dataType] : getRawData(dataType);

    return AudioState(
      $medias: getData(AudioRawData.medias),
      $currentIndex: getData(AudioRawData.currentIndex),
      $shuffled: getData(AudioRawData.shuffled),
      $playing: getData(AudioRawData.playing),
      $playlistMode: getData(AudioRawData.playlistMode),
      $volume: getData(AudioRawData.volume),
      $buffer: getData(AudioRawData.buffer),
      $position: getData(AudioRawData.position),
      $duration: getData(AudioRawData.duration),
      $rate: getData(AudioRawData.rate),
      $buffering: getData(AudioRawData.buffering),
      $completed: getData(AudioRawData.completed),
    );
  }

  static final AudioState defaultState = AudioState(
    $medias: [],
    $currentIndex: 0,
    $shuffled: false,
    $playing: false,
    $playlistMode: PlaylistMode.none,
    $volume: 100,
    $buffer: Duration.zero,
    $position: Duration.zero,
    $duration: Duration.zero,
    $rate: 1.0,
    $buffering: false,
    $completed: false,
  );
}

abstract class AudioDataContainer {
  List<Media> get $medias;
  int get $currentIndex;
  bool get $shuffled;
  bool get $playing;
  PlaylistMode get $playlistMode;
  double get $volume;
  Duration get $buffer;
  Duration get $position;
  Duration get $duration;
  double get $rate;
  bool get $buffering;
  bool get $completed;

  List<MusicData> get playlist => getPlaylist($medias);
  int? get currentIndex => getCurrentIndex($currentIndex, $medias);
  MusicData? get currentSong => getCurrentSong($currentIndex, $medias);
  PlayingState get playingState => getPlayingState($playing, $medias);
  RepeatState get repeatState => getRepeatState($playlistMode);
  bool get shuffled => $shuffled;
  bool get hasNext => getHasNext($currentIndex, $medias, $playlistMode);
  double get currentSongVolume => currentSong?.volume ?? 1.0;
  double get volume => $volume / 100;

  Duration get buffer => $buffer;
  Duration get position => currentIndex == null ? Duration.zero : $position;
  Duration get duration => $duration;
  ProgressBarState get progress => getProgress(position, $buffer, $duration);

  double get speed => $rate;
  bool get buffering => $buffering;
  bool get completed => $completed;
  AudioProcessingState get processingState =>
      getProcessingState($medias, $buffering, $completed);

  dynamic getRawData(AudioRawData data) {
    switch (data) {
      case AudioRawData.medias:
        return $medias;
      case AudioRawData.currentIndex:
        return $currentIndex;
      case AudioRawData.shuffled:
        return $shuffled;
      case AudioRawData.playing:
        return $playing;
      case AudioRawData.playlistMode:
        return $playlistMode;
      case AudioRawData.volume:
        return $volume;
      case AudioRawData.buffer:
        return $buffer;
      case AudioRawData.position:
        return $position;
      case AudioRawData.duration:
        return $duration;
      case AudioRawData.rate:
        return $rate;
      case AudioRawData.buffering:
        return $buffering;
      case AudioRawData.completed:
        return $completed;
    }
  }

  dynamic getRichData(AudioRichData data) {
    switch (data) {
      case AudioRichData.playlist:
        return playlist;
      case AudioRichData.currentIndex:
        return currentIndex;
      case AudioRichData.currentSong:
        return currentSong;
      case AudioRichData.playingState:
        return playingState;
      case AudioRichData.repeatState:
        return repeatState;
      case AudioRichData.shuffled:
        return shuffled;
      case AudioRichData.hasNext:
        return hasNext;
      case AudioRichData.currentSongVolume:
        return currentSongVolume;
      case AudioRichData.volume:
        return volume;
      case AudioRichData.buffer:
        return buffer;
      case AudioRichData.position:
        return position;
      case AudioRichData.duration:
        return duration;
      case AudioRichData.progress:
        return progress;
      case AudioRichData.speed:
        return speed;
      case AudioRichData.buffering:
        return buffering;
      case AudioRichData.completed:
        return completed;
    }
  }

  static List<MusicData> getPlaylist(List<Media> medias) {
    final playlist = medias;
    return playlist.map((media) => media.toMusicData()).toList();
  }

  static int? getCurrentIndex(int index, List<Media> medias) {
    if (medias.isEmpty) return null;
    return min(index, medias.length - 1);
  }

  static MusicData? getCurrentSong(int index, List<Media> medias) {
    if (index >= medias.length || index < 0) return null;
    return medias[index].toMusicData();
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
      Duration position, Duration buffer, Duration duration) {
    return ProgressBarState(
        position: position, buffer: buffer, duration: duration);
  }

  static RepeatState getRepeatState(PlaylistMode playlistMode) {
    return playlistModeToRepeatState(playlistMode);
  }

  static bool getHasNext(
      int index, List<Media> medias, PlaylistMode playlistMode) {
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

  static AudioProcessingState getProcessingState(
      List<Media> medias, bool buffering, bool completed) {
    if (medias.isEmpty) {
      return AudioProcessingState.idle;
    } else if (buffering) {
      return AudioProcessingState.buffering;
    } else if (completed) {
      return AudioProcessingState.completed;
    } else {
      return AudioProcessingState.ready;
    }
  }
}

enum PlayingState { paused, playing, loading, disabled }

enum AudioRawData {
  medias,
  currentIndex,
  shuffled,
  playing,
  playlistMode,
  volume,
  buffer,
  position,
  duration,
  rate,
  buffering,
  completed,
}

enum AudioRichData {
  playlist,
  currentIndex,
  currentSong,
  playingState,
  repeatState,
  shuffled,
  hasNext,
  currentSongVolume,
  volume,
  buffer,
  position,
  duration,
  progress,
  speed,
  buffering,
  completed,
}

class ProgressBarState {
  const ProgressBarState({
    required this.position,
    required this.buffer,
    required this.duration,
  });
  final Duration position;
  final Duration buffer;
  final Duration duration;
}
