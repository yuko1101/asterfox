import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/music_downloader.dart';
import 'package:flutter/material.dart';


class DownloadButton extends StatelessWidget {
  const DownloadButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioBase?>(
      valueListenable: musicManager.currentSongNotifier,
      builder: (_, song, __) {
        return ValueListenableBuilder<List<String>>(
          valueListenable: downloading,
          builder: (_, downloadingSongs, __) {
            print("download changed!");
            final downloadable = song != null;
            final isDownloading = downloadingSongs.contains(song?.key);
            if (isDownloading) {
              return const CircularProgressIndicator();
            }
            return IconButton(
                onPressed: downloadable ? () => MusicDownloader.download(song) : null,
                icon: const Icon(Icons.file_download)
            );
          }
        );
      }
    );
  }
}
