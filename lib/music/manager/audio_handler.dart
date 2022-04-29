import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/util/os.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {

  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  /// Initialise our audio handler.
  AudioPlayerHandler() {
    // So that our clients (the Flutter UI and the system notification) know
    // what state to display, here we set up our audio handler to broadcast all
    // playback state changes as they happen via playbackState...
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // _notifyAudioHandlerAboutPlaybackEvents();

    // Load the player.
    _player.setAudioSource(_playlist);

    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  // In this simple example, we handle only 4 actions: play, pause, seek and
  // stop. Any button press from the Flutter UI, notification, lock screen or
  // headset will be routed through to these 4 methods so that you can handle
  // your audio playback logic in one place.

  @override
  Future<void> play() async {
    print("before play()");
    await _player.play();
    print("after play() playing: ${_player.playing}");
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // manage Just Audio
    final AudioSource audioSource = _createAudioSource(mediaItem);

    OS.getOS() != OSType.windows
        ? await _add(audioSource)
        : _add(audioSource);

    // // notify system
    // final newQueue = queue.value..add(mediaItem);
    // queue.add(newQueue);

  }

  Future<void> _add(AudioSource audioSource) async {
    await _playlist.add(audioSource);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    await _playlist.addAll(audioSource.toList());

    // // notify system
    // final newQueue = queue.value..addAll(mediaItems);
    // queue.add(newQueue);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    // manage Just Audio
    await _playlist.removeAt(index);

    // // notify system
    // final newQueue = queue.value..removeAt(index);
    // queue.add(newQueue);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await _player.setShuffleModeEnabled(false);
    } else {
      await _player.shuffle();
      await _player.setShuffleModeEnabled(true);
    }
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == "move") {
      await move(extras!["oldIndex"] as int, extras["newIndex"] as int);
    }
  }

  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    // print(mediaItem.asMusicData());
    return AudioSource.uri(
      Uri.parse(mediaItem.extras!['url']),
      tag: mediaItem.asAudioBase(), // MusicData
    );
  }

  Future<void> move(int currentIndex, int newIndex) async {
    await _playlist.move(currentIndex, newIndex);
    // final targetSong = queue.value[currentIndex];
    // final newQueue = queue.value..removeAt(currentIndex);
    // newQueue.insert(newIndex, targetSong);
    // queue.add(newQueue);
  }

  AudioPlayer getAudioPlayer() {
    return _player;
  }


  /// Transform a just_audio event into an audio_service state.
  ///
  /// This method is used from the constructor. Every event received from the
  /// just_audio player will be transformed into an audio_service state so that
  /// it can be broadcast to audio_service clients.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      var index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      mediaItem.add(playlist[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      // print("sequenceState: ${sequenceState?.effectiveSequence.length ?? 0} songs");
      var sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) sequence = [];
      final items = sequence.map((source) => source.asAudioBase().getMediaItem());
      // print(items.length.toString() + " added songs");
      setQueueItems(items.toList());
    });
  }

  Future<void> setQueueItems(List<MediaItem> songs) async {
    // notify system
    final newQueue = queue.value..clear()..addAll(songs.toSet().toList());
    queue.add(newQueue);
    // print("set to ${queue.valueOrNull?.length ?? 0} songs");
  }

}
