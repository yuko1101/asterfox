import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart';

import '../../data/settings_data.dart';
import '../../main.dart';
import '../audio_source/music_data.dart';
import 'notifiers/audio_state_notifier.dart';

class SessionAudioHandler extends BaseAudioHandler with SeekHandler {
  final Player _player = Player();
  bool playerOpened = false;

  final bool useSession;
  final bool handleInterruptions;

  /// Initialize the audio handler.
  SessionAudioHandler(this.useSession, this.handleInterruptions) {
    // TODO: implement this
    // _androidEnhancer.setEnabled(true);
    // _pipeline = AudioPipeline(androidAudioEffects: [_androidEnhancer]);
    // _player = AudioPlayer(
    //   audioPipeline: _pipeline,
    //   handleInterruptions: handleInterruptions,
    //   handleAudioSessionActivation: handleInterruptions,
    // );

    // So that our clients (the Flutter UI and the system notification) know
    // what state to display, here we set up our audio handler to broadcast all
    // playback state changes as they happen via playbackState...
    if (useSession) {
      _player.stream.playlist.map(_transformEvent).pipe(playbackState);
      _activateAudioSession();
    }

    // Disabling handleInterruptions also cause to disable listening becomingNoisyEventStream.
    // So this listens instead.
    if (!handleInterruptions) {
      _listenBecomingNoisyEventStream();
    }

    // _notifyAudioHandlerAboutPlaybackEvents();

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
    print("after play() playing: ${_player.state.playing}");
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position, {int? index}) async {
    if (index != null) {
      await _player.jump(index);
      if (position == Duration.zero) {
        return;
      }
    }
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    return await super.stop();
  }

  // forced skip
  @override
  Future<void> skipToNext() async {
    if (_player.state.playlistMode == PlaylistMode.single) {
      final int currentIndex = _player.state.playlist.index;
      final int nextIndex =
          (currentIndex + 1) % _player.state.playlist.medias.length;
      await seek(Duration.zero, index: nextIndex);
    } else {
      await _player.next();
    }
  }

  // non-forced skip
  Future<void> skipToNextUnforced() async {
    await _player.next();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.state.playlistMode == PlaylistMode.single) {
      final int currentIndex = _player.state.playlist.index;
      final int previousIndex =
          (currentIndex - 1) % _player.state.playlist.medias.length;
      await seek(Duration.zero, index: previousIndex);
    } else {
      await _player.previous();
    }
  }

  Future<void> skipToPreviousUnforced() async {
    await _player.previous();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final Media audioSource = _createAudioSource(mediaItem);
    await _add(audioSource);
  }

  Future<void> _add(Media audioSource) async {
    if (!playerOpened) {
      playerOpened = true;
      await _player.open(Playlist([audioSource]));
    } else {
      await _player.add(audioSource);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSource = mediaItems.map(_createAudioSource);
    if (!playerOpened) {
      playerOpened = true;
      await _player.open(Playlist(audioSource.toList()));
    } else {
      for (final source in audioSource) {
        await _player.add(source);
      }
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    throw UnimplementedError();
    // TODO: implement this
    // final audioSource = _createAudioSource(mediaItem);
    // await _playlist.insert(index, audioSource);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _player.remove(index);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setPlaylistMode(PlaylistMode.none);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setPlaylistMode(PlaylistMode.single);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        await _player.setPlaylistMode(PlaylistMode.loop);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await _player.setShuffle(false);
    } else {
      await _player.setShuffle(true);
    }
  }

  @override
  Future<void> onNotificationDeleted() async {
    // exit if queue is not empty meaning that the notification was deleted by the user (not working right now)
    // TODO: safe exit
    if (queue.value.isNotEmpty) exitApp(true);
    await super.onNotificationDeleted();
  }

  Media _createAudioSource(MediaItem mediaItem) {
    return Media(
      mediaItem.extras!['url'],
      extras: {
        "key": mediaItem.id,
        "url": mediaItem.extras!['url'],
        "duration": mediaItem.duration?.inMilliseconds ?? 0,
      },
    );
  }

  MediaItem _createMediaItem(Media audioSource) {
    final MusicData musicData = audioSource.toMusicData();
    return musicData.toMediaItemWithUrl(audioSource.extras!["url"]);
  }

  Future<void> move(
      int oldIndex, int newIndex, MainAudioStateNotifier? mainNotifier) async {
    throw UnimplementedError();
    // TODO: implement this
    // final bool shuffled = audioPlayer.shuffleModeEnabled;
    // if (shuffled) {
    //   final shuffleIndices = _playlist.shuffleOrder.indices;
    //   shuffleIndices.insert(newIndex, shuffleIndices.removeAt(oldIndex));

    //   // add nothing to update playlist with new shuffle order
    //   await _playlist.addAll([]);
    // } else {
    //   final currentIndex = _player.currentIndex;
    //   final newCurrentIndex = () {
    //     if (currentIndex == null) return null;
    //     if (oldIndex == newIndex) return currentIndex;
    //     if (currentIndex == oldIndex) return newIndex;

    //     if (oldIndex < newIndex) {
    //       if (currentIndex > oldIndex && currentIndex <= newIndex) {
    //         return currentIndex - 1;
    //       } else {
    //         return currentIndex;
    //       }
    //     }

    //     if (currentIndex >= newIndex && currentIndex < oldIndex) {
    //       return currentIndex + 1;
    //     } else {
    //       return currentIndex;
    //     }
    //   }();
    //   if (mainNotifier != null) {
    //     mainNotifier.update({"currentIndex": newCurrentIndex});
    //     mainNotifier.pauseChange("currentIndex");
    //   }
    //   await _playlist.move(oldIndex, newIndex);
    //   if (mainNotifier != null) {
    //     mainNotifier.resumeChange("currentIndex");
    //   }
    // }
  }

  Future<void> clear() async {
    throw UnimplementedError();
    // TODO: implement this
    // await _playlist.clear();
  }

  Future<void> setSongs(List<MusicData> songs) async {
    throw UnimplementedError();
    // TODO: implement this
    // final mediaItems = await Future.wait(songs.map((e) => e.toMediaItem()));
    // _playlist = ConcatenatingAudioSource(
    //     children: mediaItems.map(_createAudioSource).toList());
    // await _player.setAudioSource(_playlist);
  }

  Player get audioPlayer => _player;

  /// Transform a just_audio event into an audio_service state.
  ///
  /// This method is used from the constructor. Every event received from the
  /// just_audio player will be transformed into an audio_service state so that
  /// it can be broadcast to audio_service clients.
  PlaybackState _transformEvent(Playlist playlist) {
    return PlaybackState(
      controls: [
        const MediaControl(
          androidIcon: "drawable/ic_skip_previous",
          label: "Skip Previous",
          action: MediaAction.skipToPrevious,
        ),
        const MediaControl(
          androidIcon: "drawable/ic_fast_rewind",
          label: "Fast Rewind",
          action: MediaAction.rewind,
        ),
        _player.state.playing ? MediaControl.pause : MediaControl.play,
        const MediaControl(
          androidIcon: "drawable/ic_fast_forward",
          label: "Fast Forward",
          action: MediaAction.fastForward,
        ),
        const MediaControl(
          androidIcon: "drawable/ic_skip_next",
          label: "Skip Next",
          action: MediaAction.skipToNext,
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      repeatMode: const {
        PlaylistMode.none: AudioServiceRepeatMode.none,
        PlaylistMode.single: AudioServiceRepeatMode.one,
        PlaylistMode.loop: AudioServiceRepeatMode.all,
      }[_player.state.playlistMode]!,
      // TODO: implement this
      // shuffleMode: _player.shuffleModeEnabled
      //     ? AudioServiceShuffleMode.all
      //     : AudioServiceShuffleMode.none,
      androidCompactActionIndices: const [0, 2, 4],
      // TODO: implement this
      // processingState: const {
      //   ProcessingState.idle: AudioProcessingState.idle,
      //   ProcessingState.loading: AudioProcessingState.loading,
      //   ProcessingState.buffering: AudioProcessingState.buffering,
      //   ProcessingState.ready: AudioProcessingState.ready,
      //   ProcessingState.completed: AudioProcessingState.completed,
      // }[_player.processingState]!,
      playing: _player.state.playing,
      updatePosition: _player.state.position,
      bufferedPosition: _player.state.buffer,
      speed: _player.state.rate,
      queueIndex: playlist.index,
    );
  }

  void _listenForDurationChanges() {
    _player.stream.duration.listen((duration) {
      var index = _player.state.playlist.index;
      final newQueue = queue.value;

      if (newQueue.isEmpty) return;
      if (index >= newQueue.length) return;

      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.stream.playlist.listen((playlist) {
      final index = playlist.index;
      print("index:$index");
      final q = queue.value;

      if (q.isEmpty) return;
      if (index >= q.length) return;

      mediaItem.add(q[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    _player.stream.playlist.listen((playlist) async {
      // print("sequenceState: ${sequenceState?.effectiveSequence.length ?? 0} songs");
      var sequence = playlist.medias;
      final items = sequence.map(_createMediaItem);
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
      await _player.seek(Duration.zero);
    }
  }

  Future<void> _activateAudioSession() async {
    final audioChannel = SettingsData.getValue(key: "audioChannel") as String;
    final usage = audioChannel == "call"
        ? AndroidAudioUsage.voiceCommunication
        : audioChannel == "call_speaker"
            ? AndroidAudioUsage.voiceCommunication
            : audioChannel == "notification"
                ? AndroidAudioUsage.notification
                : audioChannel == "alarm"
                    ? AndroidAudioUsage.alarm
                    : AndroidAudioUsage.media;

    final isCallSpeaker = audioChannel == "call_speaker";

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: usage,
        flags: isCallSpeaker
            ? AndroidAudioFlags.audibilityEnforced
            : AndroidAudioFlags.none,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));
  }

  Future<void> _listenBecomingNoisyEventStream() async {
    final session = await AudioSession.instance;
    session.becomingNoisyEventStream.listen((_) {
      _player.pause();
    });
  }
}
