import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/util/os.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class WindowsAudioHandler {
  final _player = AudioPlayer(handleInterruptions: false);
  final _playlist = ConcatenatingAudioSource(children: []);

  /// Initialise our audio handler.
  WindowsAudioHandler() {

    // _notifyAudioHandlerAboutPlaybackEvents();

    // Load the player.
    _player.setAudioSource(_playlist);
  }

  // In this simple example, we handle only 4 actions: play, pause, seek and
  // stop. Any button press from the Flutter UI, notification, lock screen or
  // headset will be routed through to these 4 methods so that you can handle
  // your audio playback logic in one place.

  Future<void> play() async {
    print("before play()");
    _player.play();
    print("after play() playing: ${_player.playing}");
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> skipToNext() async {
    await _player.seekToNext();
  }

  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
  }

  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    _playlist.addAll(audioSource.toList());

  }

  Future<void> addQueueItem(MediaItem mediaItem) async {
    print(3);

    // manage Just Audio
    final audioSource = _createAudioSource(mediaItem);
    print(3.5);

    _playlist.add(audioSource);
    print(4);

  }

  Future<void> removeQueueItemAt(int index) async {
    // manage Just Audio
    await _playlist.removeAt(index);

  }

  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        _player.setLoopMode(LoopMode.all);
        break;
    }
  }


  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      _player.setShuffleModeEnabled(false);
    } else {
      await _player.shuffle();
      _player.setShuffleModeEnabled(true);
    }
  }


  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    // print(mediaItem.asMusicData());
    return AudioSource.uri(
      Uri.parse(mediaItem.extras!['url']),
      tag: mediaItem.asMusicData(), // MusicData
    );
  }

  Future<void> move(int currentIndex, int newIndex) async {
    await _playlist.move(currentIndex, newIndex);
  }

  AudioPlayer getAudioPlayer() {
    return _player;
  }
}
