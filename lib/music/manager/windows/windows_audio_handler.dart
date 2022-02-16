import 'dart:async';
import 'dart:io';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/util/os.dart';
import 'package:audio_service/audio_service.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class WindowsAudioHandler {
  final _player = Player(
    id: 69420,
    commandlineArguments: ['--no-video']
  );

  /// Initialise our audio handler.
  WindowsAudioHandler() {

    // _notifyAudioHandlerAboutPlaybackEvents();

    // Load the player.
    _player.open(const Playlist(medias: []));
  }

  // In this simple example, we handle only 4 actions: play, pause, seek and
  // stop. Any button press from the Flutter UI, notification, lock screen or
  // headset will be routed through to these 4 methods so that you can handle
  // your audio playback logic in one place.

  Future<void> play() async {
    print("before play()");
    _player.play();
    print("after play() playing: ${_player.playback.isPlaying}");
  }

  Future<void> pause() async {
    _player.pause();
  }

  Future<void> seek(Duration position) async {
    _player.seek(position);
  }

  Future<void> stop() async {
    _player.stop();
  }

  Future<void> skipToNext() async {
    _player.next();
  }

  Future<void> skipToPrevious() async {
    _player.back();
  }

  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio
    for (final mediaItem in mediaItems) {
      addQueueItem(mediaItem);
    }

  }

  Future<void> addQueueItem(MediaItem mediaItem) async {
    print(3);

    // manage Just Audio
    final media = _createMedia(mediaItem);
    print(3.5);

    _player.add(media);
    musicManager.playlistNotifier.value = [...musicManager.playlistNotifier.value, mediaItem.asMusicData()];
    print(4);

  }

  Future<void> removeQueueItemAt(int index) async {
    _player.remove(index);
    final playlist = musicManager.playlistNotifier.value;
    playlist.removeAt(index);
    musicManager.playlistNotifier.value = playlist;

    // dart_vlcでは0曲になったときの処理ができないためここで代わりに処理をする
    if (playlist.isEmpty) {
      print("no songs!");
      musicManager.currentSongNotifier.value = null;
    }
  }

  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _player.setPlaylistMode(PlaylistMode.single);
        break;
      case AudioServiceRepeatMode.one:
        _player.setPlaylistMode(PlaylistMode.repeat);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        _player.setPlaylistMode(PlaylistMode.loop);
        break;
    }
  }


  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    // if (shuffleMode == AudioServiceShuffleMode.none) {
    //   _player.setShuffleModeEnabled(false);
    // } else {
    //   await _player.shuffle();
    //   _player.setShuffleModeEnabled(true);
    // }
  }


  Media _createMedia(MediaItem mediaItem) {
    // print(mediaItem.asMusicData());
    if (mediaItem.extras!["tag"]["isLocal"]) {
      return Media.file(File(mediaItem.extras!["url"]));
    }
    return Media.network(
      Uri.parse(mediaItem.extras!["url"])// MusicData
    );
  }

  Future<void> move(int currentIndex, int newIndex) async {
    _player.move(currentIndex, newIndex);
    final newPlaylist = musicManager.playlistNotifier.value;
    final removed = newPlaylist.removeAt(currentIndex);
    final insertIndex = currentIndex < newIndex ? newIndex - 1 : newIndex;
    newPlaylist.insert(insertIndex, removed);
    musicManager.playlistNotifier.value = newPlaylist;
  }

  Player getAudioPlayer() {
    return _player;
  }
}
