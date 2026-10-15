import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../../data/local_musics_data.dart';
import '../../main.dart';
import '../music_data/music_data.dart';
import 'audio_data_manager.dart';

/// The player a preview is heard on.
///
/// Everything below this point is libmpv, so this is the seam a test replaces.
abstract class PreviewPlayer {
  /// Opens [url], which starts playing it.
  Future<void> open(String url);

  Future<void> play();

  Future<void> pause();

  /// Unloads the song, so that nothing of it plays on.
  Future<void> stop();

  Future<void> seek(Duration position);

  /// [volume] is in the same 0.0 to 1.0 range the queue player is given.
  Future<void> setVolume(double volume);

  Future<void> dispose();

  Stream<bool> get playing;
  Stream<bool> get completed;
  Stream<Duration> get position;
  Stream<Duration> get duration;
  Stream<Duration> get buffer;
}

class MediaKitPreviewPlayer implements PreviewPlayer {
  MediaKitPreviewPlayer() : _player = Player();

  final Player _player;

  @override
  Future<void> open(String url) => _player.open(Media(url));

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume * 100);

  @override
  Future<void> dispose() => _player.dispose();

  @override
  Stream<bool> get playing => _player.stream.playing;

  @override
  Stream<bool> get completed => _player.stream.completed;

  @override
  Stream<Duration> get position => _player.stream.position;

  @override
  Stream<Duration> get duration => _player.stream.duration;

  @override
  Stream<Duration> get buffer => _player.stream.buffer;
}

/// The queue a preview stands aside for.
abstract class QueuePlayback {
  const QueuePlayback();

  /// Whether the queue is playing right now.
  bool get playing;

  Future<void> pause();

  Future<void> resume();

  /// The volume the queue is heard at, which a preview is heard at too.
  double get volume;
}

class MusicManagerPlayback extends QueuePlayback {
  const MusicManagerPlayback();

  @override
  bool get playing => musicManager.state.playingState == PlayingState.playing;

  @override
  Future<void> pause() => musicManager.pause();

  @override
  Future<void> resume() => musicManager.play();

  @override
  double get volume => musicManager.muteNotifier.value
      ? 0
      : musicManager.baseVolumeNotifier.value;
}

/// The video a preview is on, and the song that is heard of it.
class PreviewingVideo {
  const PreviewingVideo({required this.videoId, required this.song});

  final String videoId;
  final MusicData<CachingDisabled> song;
}

/// Listening to one song on its own.
/// A preview is a song heard before anything is decided about it: it enters no
/// queue, no history and no library. Only the queue is stood aside for — it is
/// paused when the preview takes the listening over, and taken up again where
/// it was when the preview ends, so that a preview leaves the app playing what
/// it was playing.
class SongPreview {
  SongPreview({
    PreviewPlayer Function()? createPlayer,
    QueuePlayback queue = const MusicManagerPlayback(),
  })  : _createPlayer = createPlayer ?? MediaKitPreviewPlayer.new,
        _queue = queue;

  final PreviewPlayer Function() _createPlayer;
  final QueuePlayback _queue;

  PreviewPlayer? _player;
  final List<StreamSubscription> _subscriptions = [];

  /// The video being previewed, or null while no preview is on.
  ///
  /// The video the song came from is kept next to the song: the song of a video
  /// is fetched from its url, so the row it was tapped on is known by the video
  /// rather than by anything the song carries.
  final ValueNotifier<PreviewingVideo?> previewing = ValueNotifier(null);

  /// Whether the preview is playing right now.
  final ValueNotifier<bool> playing = ValueNotifier(false);

  /// Where in the song the preview is.
  final ValueNotifier<ProgressBarState> progress = ValueNotifier(
    const ProgressBarState(
      position: Duration.zero,
      buffer: Duration.zero,
      duration: Duration.zero,
    ),
  );

  /// Whether the queue was playing when the preview took the listening over.
  bool _queueWasPlaying = false;

  /// Counts the previews, so that the audio of an earlier one can be told apart
  /// from the audio of the one that replaced it.
  int _previewId = 0;

  bool _disposed = false;

  /// The song being previewed, or null while no preview is on.
  MusicData<CachingDisabled>? get song => previewing.value?.song;

  /// Previews the audio of the video [videoId], which is the song [song].
  ///
  /// Throws what fetching the audio of [song] throws, so that the caller can
  /// say why the preview did not start.
  Future<void> start(
    MusicData<CachingDisabled> song, {
    required String videoId,
  }) async {
    final preview = ++_previewId;
    final url = await song.audioUrl;
    // A later tap replaced this preview while its audio was on its way, or the
    // screen that offered it was left.
    if (_disposed || preview != _previewId) return;

    // The queue is stood aside for once: a second preview starts where the
    // first one left it, rather than pausing an already paused queue.
    if (previewing.value == null) {
      _queueWasPlaying = _queue.playing;
      if (_queueWasPlaying) await _queue.pause();
    }

    final player = _playerFor();
    previewing.value = PreviewingVideo(videoId: videoId, song: song);
    progress.value = ProgressBarState(
      position: Duration.zero,
      buffer: Duration.zero,
      duration: song.duration,
    );
    await player.setVolume(_queue.volume);
    await player.open(url);
  }

  /// Ends the preview and leaves the queue playing again.
  Future<void> stop() async {
    // An audio that is still on its way belongs to no preview any more.
    _previewId++;

    if (previewing.value == null) return;
    previewing.value = null;
    playing.value = false;
    progress.value = const ProgressBarState(
      position: Duration.zero,
      buffer: Duration.zero,
      duration: Duration.zero,
    );

    await _player?.stop();

    if (_queueWasPlaying) {
      _queueWasPlaying = false;
      await _queue.resume();
    }
  }

  /// Plays or pauses the preview.
  Future<void> togglePlay() async {
    final player = _player;
    if (player == null || previewing.value == null) return;
    if (playing.value) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  /// Moves the preview to [position].
  Future<void> seek(Duration position) async {
    if (previewing.value == null) return;
    await _player?.seek(position);
  }

  /// Ends the preview and releases everything it holds.
  Future<void> dispose() async {
    if (_disposed) return;
    await stop();
    _disposed = true;
    // The subscriptions first: they are what writes the notifiers, and a
    // disposed notifier is not to be written to.
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    final player = _player;
    _player = null;
    await player?.dispose();
    previewing.dispose();
    playing.dispose();
    progress.dispose();
  }

  /// The player of this preview, made the first time a song is previewed.
  ///
  /// A player is only worth holding while a song is heard through it, so the
  /// screen that offers a preview can be opened without one.
  PreviewPlayer _playerFor() {
    final existing = _player;
    if (existing != null) return existing;

    final player = _createPlayer();
    _player = player;
    _subscriptions.addAll([
      player.playing.listen((value) => playing.value = value),
      player.completed.listen((value) {
        if (value) playing.value = false;
      }),
      player.position.listen((value) => _updateProgress(position: value)),
      player.duration.listen((value) => _updateProgress(duration: value)),
      player.buffer.listen((value) => _updateProgress(buffer: value)),
    ]);
    return player;
  }

  void _updateProgress({
    Duration? position,
    Duration? buffer,
    Duration? duration,
  }) {
    final current = progress.value;
    progress.value = ProgressBarState(
      position: position ?? current.position,
      buffer: buffer ?? current.buffer,
      duration: duration ?? current.duration,
    );
  }
}
