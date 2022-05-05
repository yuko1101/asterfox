import 'dart:io';

import 'package:asterfox/util/os.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler {

  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  // fix that the audio player is not working when the empty playlist is added
  final fix = OS.getOS() == OSType.windows;

  AudioPlayerHandler() {
     if (!fix) _player.setAudioSource(_playlist);

  }

  Future<void> play() async {
    print("before play()");
    await _player.play();
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

  Future<void> addQueueItem(AudioSource audioSource) async {
    await _add(audioSource);
  }

  Future<void> _add(AudioSource audioSource) async {
    final wasEmpty = (_player.sequence ?? []).isEmpty;
    await _playlist.add(audioSource);
    if (wasEmpty && fix) {
      await _player.setAudioSource(_playlist);
    }
  }

  Future<void> addQueueItems(List<AudioSource> audioSourceList) async {
    await _playlist.addAll(audioSourceList);
  }

  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);
  }

  Future<void> setRepeatMode(LoopMode repeatMode) async {
    await _player.setLoopMode(repeatMode);
  }

  Future<void> setShuffleMode(bool shuffleMode) async {
    if (!shuffleMode) {
      await _player.setShuffleModeEnabled(false);
    } else {
      await _player.shuffle();
      await _player.setShuffleModeEnabled(true);
    }
  }


  Future<void> move(int currentIndex, int newIndex) async {
    await _playlist.move(currentIndex, newIndex);
  }

  AudioPlayer getAudioPlayer() {
    return _player;
  }

  ConcatenatingAudioSource getPlaylist() {
    return _playlist;
  }


}
