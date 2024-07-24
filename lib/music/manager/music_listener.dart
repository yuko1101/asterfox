import 'package:media_kit/media_kit.dart';
import 'audio_data_manager.dart';
import 'audio_player.dart';
import 'music_manager.dart';

class MusicListener {
  MusicListener(this._musicManager, this._audioPlayer);
  final MusicManager _musicManager;
  final AudioPlayer _audioPlayer;

  void init() {
    _audioPlayer.stream.playlist.listen((playlist) {
      _updatePlaylistAndIndex(playlist);
    });
    _audioPlayer.stream.playing.listen((playing) {
      _updatePlaybackState(playing);
    });

    _audioPlayer.stream.position.listen((position) {
      _updatePosition(position);
    });
    _audioPlayer.stream.buffer.listen((buffer) {
      _updateBuffer(buffer);
    });
    _audioPlayer.stream.duration.listen((duration) {
      _updateDuration(duration);
    });
    _audioPlayer.stream.playlistMode.listen((playlistMode) {
      _updatePlaylistMode(playlistMode);
    });
    _audioPlayer.stream.volume.listen((volume) {
      _updateVolume(volume);
    });
  }

  void _updatePlaylistAndIndex(Playlist playlist) {
    _musicManager.notifier.update({
      AudioRawData.medias: playlist.medias,
      AudioRawData.currentIndex: playlist.index,
    });
  }

  void _updatePlaybackState(bool playing) {
    _musicManager.notifier.update({
      AudioRawData.playing: playing,
    });
  }

  void _updatePosition(Duration position) {
    _musicManager.notifier.update({
      AudioRawData.position: position,
    });
  }

  void _updateBuffer(Duration buffer) {
    _musicManager.notifier.update({
      AudioRawData.buffer: buffer,
    });
  }

  void _updateDuration(Duration duration) {
    _musicManager.notifier.update({
      AudioRawData.duration: duration,
    });
  }

  void _updatePlaylistMode(PlaylistMode playlistMode) {
    _musicManager.notifier.update({
      AudioRawData.playlistMode: playlistMode,
    });
  }

  void _updateVolume(double volume) {
    _musicManager.notifier.update({
      AudioRawData.volume: volume,
    });
  }
}
