import 'package:audio_service/audio_service.dart';
import 'package:easy_app/utils/os.dart';
import 'package:just_audio/just_audio.dart';

import '../../utils/bubble_sort.dart';
import '../audio_source/music_data.dart';
import 'audio_data_manager.dart';

class SessionAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  var _playlist = ConcatenatingAudioSource(children: []);

  // fix that the audio player is not working when the empty playlist is added
  final fix = OS.getOS() == OSType.windows;
  final bool useSession;

  /// Initialise the audio handler.
  SessionAudioHandler(this.useSession) {
    // So that our clients (the Flutter UI and the system notification) know
    // what state to display, here we set up our audio handler to broadcast all
    // playback state changes as they happen via playbackState...
    if (useSession) {
      _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    }

    // _notifyAudioHandlerAboutPlaybackEvents();

    // Load the player.
    if (!fix) _player.setAudioSource(_playlist);

    if (useSession) {
      _listenForDurationChanges();
      _listenForCurrentSongIndexChanges();
      _listenForSequenceStateChanges();
    }
  }

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

  // forced skip
  @override
  Future<void> skipToNext() async {
    if (_player.loopMode == LoopMode.one) {
      final int? currentIndex = _player.currentIndex;
      if (currentIndex == null) return;
      final int nextIndex =
          (currentIndex + 1) % (_player.sequence ?? []).length;
      await _player.seek(Duration.zero, index: nextIndex);
    } else {
      await _player.seekToNext();
    }
  }

  // non-forced skip
  Future<void> skipToNextUnforced() async {
    await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.loopMode == LoopMode.one) {
      final int? currentIndex = _player.currentIndex;
      if (currentIndex == null) return;
      final int previousIndex =
          (currentIndex - 1) % (_player.sequence ?? []).length;
      await _player.seek(Duration.zero, index: previousIndex);
    } else {
      await _player.seekToPrevious();
    }
  }

  Future<void> skipToPreviousUnforced() async {
    await _player.seekToPrevious();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final AudioSource audioSource = _createAudioSource(mediaItem);
    await _add(audioSource);
  }

  // TODO: support windows (probably called abort() in this method)
  Future<void> _add(AudioSource audioSource) async {
    final wasEmpty = (_player.sequence ?? []).isEmpty;
    await _playlist.add(audioSource);
    if (wasEmpty && fix) {
      await _player.setAudioSource(_playlist);
    }
  }

  // TODO: support windows (probably called abort() in this method)
  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSource = mediaItems.map(_createAudioSource);
    await _playlist.addAll(audioSource.toList());
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    final audioSource = _createAudioSource(mediaItem);
    await _playlist.insert(index, audioSource);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);
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
  Future<void> onNotificationDeleted() async {
    await _player.stop();
    return super.onNotificationDeleted();
  }

  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(
      Uri.parse(mediaItem.extras!['url']),
      tag: {
        "key": mediaItem.id,
        "url": mediaItem.extras!['url'],
        "duration": mediaItem.duration?.inMilliseconds ?? 0,
      }, // MusicData
    );
  }

  Future<void> move(int currentIndex, int newIndex) async {
    final bool shuffled = audioPlayer.shuffleModeEnabled;
    if (shuffled) {
      final shuffledSongs = AudioDataManager.getShuffledPlaylist(
          audioPlayer.sequence, shuffled, audioPlayer.shuffleIndices);
      final songs = AudioDataManager.getPlaylist(audioPlayer.sequence);

      // move song in shuffled playlist
      final move = shuffledSongs.removeAt(currentIndex);
      shuffledSongs.insert(newIndex, move);
      final copy = [...songs];

      await setShuffleMode(AudioServiceShuffleMode.none);

      // move original playlist to be in the same order as the shuffled playlist
      await BubbleSort<MusicData>(
        compare: (a, b) =>
            shuffledSongs.indexWhere((s) => s.key == a.key) -
            shuffledSongs.indexWhere((s) => s.key == b.key),
        move: (currentIndex, newIndex) async {
          await _playlist.move(currentIndex, newIndex);
          final move = copy.removeAt(currentIndex);
          copy.insert(newIndex, move);
          return copy;
        },
      ).sort(
          songs, (song) => shuffledSongs.indexWhere((s) => s.key == song.key));
    } else {
      await _playlist.move(currentIndex, newIndex);
    }
  }

  Future<void> clear() async {
    await _playlist.clear();
  }

  Future<void> setSongs(List<MusicData> songs) async {
    final mediaItems = await Future.wait(songs.map((e) => e.toMediaItem()));
    _playlist = ConcatenatingAudioSource(
        children: mediaItems.map(_createAudioSource).toList());
    await _player.setAudioSource(_playlist);
  }

  AudioPlayer get audioPlayer => _player;

  /// Transform a just_audio event into an audio_service state.
  ///
  /// This method is used from the constructor. Every event received from the
  /// just_audio player will be transformed into an audio_service state so that
  /// it can be broadcast to audio_service clients.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        const MediaControl(
          androidIcon: "drawable/ic_skip_previous",
          label: "Previous",
          action: MediaAction.skipToPrevious,
        ),
        MediaControl.rewind,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.fastForward,
        const MediaControl(
          action: MediaAction.skipToNext,
          label: "Next",
          androidIcon: "drawable/ic_skip_next",
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 2, 4],
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
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      print("index:$index");
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      mediaItem.add(playlist[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) async {
      // print("sequenceState: ${sequenceState?.effectiveSequence.length ?? 0} songs");
      var sequence = sequenceState?.sequence;
      if (sequence == null || sequence.isEmpty) sequence = [];
      final List<MusicData> playlist = AudioDataManager.getPlaylist(sequence);
      final items =
          await Future.wait(playlist.map((song) => song.toMediaItem()));
      // print(items.length.toString() + " added songs");
      setQueueItems(items.toList());
    });
  }

  Future<void> setQueueItems(List<MediaItem> songs) async {
    final preQueue = [...queue.value]; // make immutable (just in case)

    // notify system
    final newQueue = queue.value
      ..clear()
      ..addAll(songs.toSet().toList());
    queue.add(newQueue);
    // print("set to ${queue.valueOrNull?.length ?? 0} songs");
    final songCount = queue.value.length;
    if (songCount == 0 && preQueue.isNotEmpty) {
      // remove music notification
      await _player.stop();
      await _player.load();
    }
  }
}
