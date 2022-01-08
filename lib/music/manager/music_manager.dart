import 'package:audio_service/audio_service.dart';

import '../music_data.dart';
import 'audio_handler.dart';

class MusicManager {
  late final AudioHandler _audioHandler;

  Future<void> init() async {
    _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
        androidNotificationChannelId: 'net.asterium.asterfox.channel.audio',
        androidNotificationChannelName: 'Asterfox Music',
        androidNotificationOngoing: true,
        )
    );
  }

  Future<void> play() async {
    print("Played a playlist: " + _audioHandler.queue.value.length.toString() + " songs");
    await _audioHandler.play();
  }
  void pause() => _audioHandler.pause();

  void seek(Duration position) => _audioHandler.seek(position);

  void previous() => _audioHandler.skipToPrevious();
  void next() => _audioHandler.skipToNext();

  Future<void> add(MusicData song) async {
    await _audioHandler.addQueueItem(song.getMediaItem());
  }
  
  Future<void> move(int currentIndex, int newIndex) async {
    await _audioHandler.customAction("move", {"currentIndex": currentIndex, "newIndex": newIndex});
  }

  void stop() => _audioHandler.stop();
}