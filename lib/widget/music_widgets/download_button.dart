import 'package:flutter/material.dart';

import '../../data/local_musics_data.dart';
import '../../main.dart';
import '../../music/manager/audio_data_manager.dart';
import '../../music/music_downloader.dart';
import '../../music/utils/music_data_utils.dart';
import '../../system/home_screen_music_manager.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.currentSongNotifier,
      builder: (_, audioState, __) {
        final song = audioState.currentSong;
        return ValueListenableBuilder<List<String>>(
          valueListenable: DownloadManager.downloadingNotifier,
          builder: (_, downloadingSongs, __) {
            if (song == null) {
              return const IconButton(
                onPressed: null,
                icon: Icon(Icons.file_download),
              );
            }

            if (downloadingSongs.contains(song.audioId)) {
              return Container(
                height: 24,
                width: 24,
                margin: const EdgeInsets.only(right: 12, left: 12),
                child: Tooltip(
                  message: l10n.value.saving,
                  child: const CircularProgressIndicator(),
                ),
              );
            }

            final isDownloaded = song.isInstalled;
            if (!isDownloaded) {
              return IconButton(
                onPressed: () => HomeScreenMusicManager.download(song),
                icon: const Icon(Icons.file_download),
              );
            }

            final medias = musicManager.audioStateManager.songsNotifier.value
                .$medias[audioState.currentIndex!];
            if (medias.uri.isUrl) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    musicManager.refreshSongs(musicManager.state.currentIndex!),
              );
            }
            // TODO: implement deleting and uninstalling
            return const IconButton(
              onPressed: null,
              icon: Icon(Icons.file_download),
            );
          },
        );
      },
    );
  }
}
