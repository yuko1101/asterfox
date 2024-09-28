import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart';

import '../../data/settings_data.dart';
import '../../widget/music_widgets/repeat_button.dart';
import '../music_data/music_data.dart';
import 'audio_data_manager.dart';
import 'audio_player.dart';

class SessionAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _audioPlayer;

  final bool useSession;
  final bool handleInterruptions;

  /// Initialize the audio handler.
  SessionAudioHandler(
      this._audioPlayer, this.useSession, this.handleInterruptions) {
    // So that our clients (the Flutter UI and the system notification) know
    // what state to display, here we set up our audio handler to broadcast all
    // playback state changes as they happen via playbackState...
    if (useSession) {
      _audioPlayer.musicManager.notifier.addListener(() {
        final state = _transformEvent(_audioPlayer.musicManager.state);
        playbackState.add(state);
      });
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
    await _audioPlayer.play();
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
      mediaItem.extras!["url"],
      extras: {
        "key": mediaItem.id,
      },
    );
  }

  MediaItem _createMediaItem(Media media) {
    final musicData = media.toMusicData();
    return musicData.toMediaItemWithUrl(media.uri);
  }

  Future<void> move(int oldIndex, int newIndex) async {
    await _audioPlayer.move(oldIndex, newIndex);
  }

  Future<void> setSongs(List<MusicData<CachingEnabled>> songs) async {
    final mediaItems = await Future.wait(songs.map((e) => e.toMediaItem()));
    await _audioPlayer.setMedias(mediaItems.map(_createMedia).toList());
  }

  PlaybackState _transformEvent(AudioState state) {
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
        state.playingState == PlayingState.playing
            ? MediaControl.pause
            : MediaControl.play,
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
        RepeatState.none: AudioServiceRepeatMode.none,
        RepeatState.one: AudioServiceRepeatMode.one,
        RepeatState.all: AudioServiceRepeatMode.all,
      }[state.repeatState]!,
      shuffleMode: state.shuffled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      androidCompactActionIndices: const [0, 2, 4],
      processingState: state.processingState,
      playing: state.playingState == PlayingState.playing,
      updatePosition: state.position,
      bufferedPosition: state.buffer,
      speed: state.speed,
      queueIndex: state.currentIndex,
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
