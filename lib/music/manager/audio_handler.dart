import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart';

import '../../data/settings_data.dart';
import '../music_data/music_data.dart';
import 'audio_player.dart';
import 'music_manager.dart';
import 'notifiers/audio_state_notifier.dart';

class SessionAudioHandler extends BaseAudioHandler with SeekHandler {
  late final AudioPlayer _audioPlayer;

  final bool useSession;
  final bool handleInterruptions;

  /// Initialize the audio handler.
  SessionAudioHandler(
      MusicManager musicManager, this.useSession, this.handleInterruptions) {
    _audioPlayer = AudioPlayer(musicManager);

    // So that our clients (the Flutter UI and the system notification) know
    // what state to display, here we set up our audio handler to broadcast all
    // playback state changes as they happen via playbackState...
    if (useSession) {
      _audioPlayer.stream.playlist.map(_transformEvent).pipe(playbackState);
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
      _listenForPlaylistChanges();
    }
  }

  @override
  Future<void> play() async {
    print("before play()");
    await _audioPlayer.play();
    print("after play() playing: ${_audioPlayer.state.playing}");
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> seek(Duration position, {int? index}) async {
    if (index != null) {
      await _audioPlayer.jump(index);
      if (position == Duration.zero) {
        return;
      }
    }
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    return await super.stop();
  }

  // forced skip
  @override
  Future<void> skipToNext() async {
    await _audioPlayer.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await _audioPlayer.previous();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final Media media = _createMedia(mediaItem);
    await _audioPlayer.add(media);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final medias = mediaItems.map(_createMedia).toList();
    await _audioPlayer.addAll(medias);
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    await _audioPlayer.insert(index, _createMedia(mediaItem));
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _audioPlayer.remove(index);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _audioPlayer.setPlaylistMode(PlaylistMode.none);
        break;
      case AudioServiceRepeatMode.one:
        await _audioPlayer.setPlaylistMode(PlaylistMode.single);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        await _audioPlayer.setPlaylistMode(PlaylistMode.loop);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await _audioPlayer.setShuffle(false);
    } else {
      await _audioPlayer.setShuffle(true);
    }
  }

  @override
  Future<void> onNotificationDeleted() async {
    await super.onNotificationDeleted();
  }

  Media _createMedia(MediaItem mediaItem) {
    return Media(
      mediaItem.extras!['url'],
      extras: {
        "key": mediaItem.id,
        "url": mediaItem.extras!['url'],
        "duration": mediaItem.duration?.inMilliseconds ?? 0,
      },
    );
  }

  MediaItem _createMediaItem(Media media) {
    final MusicData musicData = media.toMusicData();
    return musicData.toMediaItemWithUrl(media.extras!["url"]);
  }

  Future<void> move(
      int oldIndex, int newIndex, MainAudioStateNotifier? mainNotifier) async {
    final currentIndex = _audioPlayer.state.playlist.index;
    final newCurrentIndex = () {
      if (oldIndex == newIndex) return currentIndex;
      if (currentIndex == oldIndex) return newIndex;

      if (oldIndex < newIndex) {
        if (currentIndex > oldIndex && currentIndex <= newIndex) {
          return currentIndex - 1;
        } else {
          return currentIndex;
        }
      }

      if (currentIndex >= newIndex && currentIndex < oldIndex) {
        return currentIndex + 1;
      } else {
        return currentIndex;
      }
    }();
    if (mainNotifier != null) {
      mainNotifier.update({"currentIndex": newCurrentIndex});
      mainNotifier.pauseChange("currentIndex");
    }
    await _audioPlayer.move(oldIndex, newIndex);
    if (mainNotifier != null) {
      mainNotifier.resumeChange("currentIndex");
    }
  }

  Future<void> clear() async {
    await _audioPlayer.clear();
  }

  Future<void> setSongs(List<MusicData> songs) async {
    final mediaItems = await Future.wait(songs.map((e) => e.toMediaItem()));
    await _audioPlayer.setMedias(mediaItems.map(_createMedia).toList());
  }

  AudioPlayer get audioPlayer => _audioPlayer;

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
        _audioPlayer.state.playing ? MediaControl.pause : MediaControl.play,
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
      }[_audioPlayer.state.playlistMode]!,
      shuffleMode: _audioPlayer.shuffled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      androidCompactActionIndices: const [0, 2, 4],
      // TODO: implement this
      // processingState: const {
      //   ProcessingState.idle: AudioProcessingState.idle,
      //   ProcessingState.loading: AudioProcessingState.loading,
      //   ProcessingState.buffering: AudioProcessingState.buffering,
      //   ProcessingState.ready: AudioProcessingState.ready,
      //   ProcessingState.completed: AudioProcessingState.completed,
      // }[_player.processingState]!,
      playing: _audioPlayer.state.playing,
      updatePosition: _audioPlayer.state.position,
      bufferedPosition: _audioPlayer.state.buffer,
      speed: _audioPlayer.state.rate,
      queueIndex: playlist.index,
    );
  }

  void _listenForDurationChanges() {
    _audioPlayer.stream.duration.listen((duration) {
      var index = _audioPlayer.state.playlist.index;
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
    _audioPlayer.stream.playlist.listen((playlist) {
      final index = playlist.index;
      print("index:$index");
      final q = queue.value;

      if (q.isEmpty) return;
      if (index >= q.length) return;

      mediaItem.add(q[index]);
    });
  }

  void _listenForPlaylistChanges() {
    _audioPlayer.stream.playlist.listen((playlist) async {
      final items = playlist.medias.map(_createMediaItem);
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
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
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
      _audioPlayer.pause();
    });
  }
}
