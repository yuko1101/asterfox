import 'dart:async';

import 'package:media_kit/media_kit.dart';

import 'audio_data_manager.dart';
import 'music_manager.dart';

class AudioPlayer extends Player {
  final MusicManager musicManager;
  bool _shuffled = false;
  bool _isEmpty = true;

  AudioPlayer(this.musicManager, {super.configuration});

  bool get shuffled => _shuffled;

  @override
  Future<void> setShuffle(bool shuffle) async {
    _shuffled = shuffle;
    await super.setShuffle(shuffle);
    musicManager.notifier.update({
      AudioRawData.shuffled: _shuffled,
    });
  }

  @override
  Future<void> stop() async {
    _isEmpty = true;
    await super.stop();
  }

  @override
  Future<void> move(int from, int to) async {
    if (from == to) return;
    if (from < to) to++;
    await super.move(from, to);
  }

  /// Sets the volume to a range between 0.0 and 1.0.
  @override
  Future<void> setVolume(double volume) async {
    await super.setVolume(volume * 100);
  }

  @override
  Future<void> add(Media media) async {
    if (_isEmpty) {
      _isEmpty = false;
      await open(Playlist([media]));
    } else {
      // TODO: remove this if statement when the bug is fixed
      // this bug is caused by the media_kit package not being able to handle the same uri in the playlist
      // media_kit caches the `extras` field by the uri of the media, and all medias have the same caching key
      // so we can't determine which media for which music data
      if (state.playlist.medias.any((e) => e.uri == media.uri)) {
        throw Exception(
            "Media with the same uri already exists in the playlist");
      }

      await super.add(media);
    }
  }

  @override
  Future<void> remove(int index) async {
    if (state.playlist.medias.length > 1) {
      await super.remove(index);
    } else {
      await stop();
    }
  }

  Future<void> addAll(List<Media> medias) async {
    if (_isEmpty) {
      _isEmpty = false;
      await open(Playlist(medias));
    } else {
      for (final media in medias) {
        // TODO: remove this if statement when the bug is fixed
        // this bug is caused by the media_kit package not being able to handle the same uri in the playlist
        // media_kit caches the `extras` field by the uri of the media, and all medias have the same caching key
        // so we can't determine which media for which music data
        if (state.playlist.medias.any((e) => e.uri == media.uri)) {
          throw Exception(
              "Media with the same uri already exists in the playlist");
        }

        await super.add(media);
      }
    }
  }

  Future<void> insert(int index, Media media) async {
    await add(media);
    await move(state.playlist.medias.length, index);
  }

  Future<void> setMedias(List<Media> medias) async {
    if (medias.isEmpty) {
      await stop();
    } else {
      await open(Playlist(medias));
    }
  }

  Future<void> cease() async {
    await pause();
  }

  Future<void> playback() async {
    if (state.position.inMilliseconds < 5000) {
      await previous();
    } else {
      await seek(Duration.zero);
    }
  }
}
