import 'dart:async';

import 'package:asterfox/music/manager/song_preview.dart';

/// A preview player that is not libmpv.
///
/// It reports what it was asked to do, so that a test can say what a preview
/// did without a device or a sound.
class FakePreviewPlayer implements PreviewPlayer {
  final List<String> opened = [];
  int plays = 0;
  int pauses = 0;
  int stops = 0;
  int disposes = 0;
  Duration? lastSeek;
  double? lastVolume;

  final StreamController<bool> _playing = StreamController<bool>.broadcast();
  final StreamController<bool> _completed = StreamController<bool>.broadcast();
  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _duration =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _buffer =
      StreamController<Duration>.broadcast();

  @override
  Future<void> open(String url) async {
    opened.add(url);
    _playing.add(true);
  }

  @override
  Future<void> play() async {
    plays++;
    _playing.add(true);
  }

  @override
  Future<void> pause() async {
    pauses++;
    _playing.add(false);
  }

  @override
  Future<void> stop() async {
    stops++;
    _playing.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }

  @override
  Future<void> dispose() async {
    disposes++;
    await _playing.close();
    await _completed.close();
    await _position.close();
    await _duration.close();
    await _buffer.close();
  }

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<bool> get completed => _completed.stream;

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<Duration> get duration => _duration.stream;

  @override
  Stream<Duration> get buffer => _buffer.stream;

  /// Lets a test report what the player is doing, the way libmpv would.
  void emitDuration(Duration value) => _duration.add(value);
  void emitBuffer(Duration value) => _buffer.add(value);
  void emitPosition(Duration value) => _position.add(value);
  void emitCompleted() => _completed.add(true);
}

/// A queue that is not the music manager.
///
/// It records what standing aside for a preview did to it, which is the whole
/// of what a preview does to the app around it.
class FakeQueue extends QueuePlayback {
  FakeQueue({bool playing = false, this.volume = 1.0}) : _playing = playing;

  bool _playing;

  @override
  bool get playing => _playing;

  @override
  final double volume;

  final List<String> calls = [];

  @override
  Future<void> pause() async {
    calls.add("pause");
    _playing = false;
  }

  @override
  Future<void> resume() async {
    calls.add("resume");
    _playing = true;
  }
}
