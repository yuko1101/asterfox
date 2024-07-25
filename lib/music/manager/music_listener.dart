import 'audio_data_manager.dart';
import 'audio_player.dart';
import 'music_manager.dart';

class MusicListener {
  MusicListener(this._musicManager, this._audioPlayer);
  final MusicManager _musicManager;
  final AudioPlayer _audioPlayer;

  void init() {
    final notifier = _musicManager.notifier;

    _audioPlayer.stream.playlist.listen((playlist) {
      notifier.update({
        AudioRawData.medias: playlist.medias,
        AudioRawData.currentIndex: playlist.index,
      });
    });
    _audioPlayer.stream.playing.listen((playing) {
      notifier.update({
        AudioRawData.playing: playing,
      });
    });

    _audioPlayer.stream.position.listen((position) {
      notifier.update({
        AudioRawData.position: position,
      });
    });
    _audioPlayer.stream.buffer.listen((buffer) {
      notifier.update({
        AudioRawData.buffer: buffer,
      });
    });
    _audioPlayer.stream.duration.listen((duration) {
      notifier.update({
        AudioRawData.duration: duration,
      });
    });
    _audioPlayer.stream.playlistMode.listen((playlistMode) {
      notifier.update({
        AudioRawData.playlistMode: playlistMode,
      });
    });
    _audioPlayer.stream.volume.listen((volume) {
      notifier.update({
        AudioRawData.volume: volume,
      });
    });
    _audioPlayer.stream.rate.listen((rate) {
      notifier.update({
        AudioRawData.rate: rate,
      });
    });
    _audioPlayer.stream.buffering.listen((buffering) {
      notifier.update({
        AudioRawData.buffering: buffering,
      });
    });
    _audioPlayer.stream.completed.listen((completed) {
      notifier.update({
        AudioRawData.completed: completed,
      });
    });
  }
}
