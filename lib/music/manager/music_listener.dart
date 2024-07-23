import 'package:media_kit/media_kit.dart';
import 'audio_data_manager.dart';
import 'audio_handler.dart';
import 'music_manager.dart';

class MusicListener {
  MusicListener(this._musicManager, this._audioHandler) {
    _audioDataManager = AudioDataManager(_audioHandler.audioPlayer);
  }
  final MusicManager _musicManager;
  final SessionAudioHandler _audioHandler;

  late AudioDataManager _audioDataManager;

  void init() {
    _audioHandler.audioPlayer.stream.playlist.listen((playlist) {
      _updatePlaylistAndIndex(playlist);
    });
    _audioHandler.audioPlayer.stream.playing.listen((playing) {
      _updatePlaybackState(playing);
    });

    _audioHandler.audioPlayer.stream.position.listen((position) {
      _updateProgress();
    });
    _audioHandler.audioPlayer.stream.buffer.listen((buffered) {
      _updateProgress();
    });
    _audioHandler.audioPlayer.stream.playlistMode.listen((playlistMode) {
      _updatePlaylistMode(playlistMode);
    });
    _audioHandler.audioPlayer.stream.volume.listen((volume) {
      _updateVolume(volume);
    });
  }

  void _updatePlaylistAndIndex(Playlist playlist) {
    _musicManager.audioStateManager.mainNotifier.update({
      AudioRawData.medias: playlist.medias,
      AudioRawData.currentIndex: playlist.index,
    });
  }

  void _updatePlaybackState(bool playing) {
    _musicManager.audioStateManager.mainNotifier.update({
      AudioRawData.playing: playing,
    });
  }

  void _updateProgress() {
    _musicManager.progressNotifier.value = _audioDataManager.progress;
  }

  void _updatePlaylistMode(PlaylistMode playlistMode) {
    _musicManager.audioStateManager.mainNotifier
        .update({AudioRawData.playlistMode: playlistMode});
  }

  void _updateVolume(double volume) {
    _musicManager.audioStateManager.mainNotifier
        .update({AudioRawData.volume: volume});
  }
}
