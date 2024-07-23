import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

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
            final downloadable = song != null && !song.isInstalled;
            final isDownloading = downloadingSongs.contains(song?.audioId);

            final List<Media> songs =
                musicManager.audioHandler.audioPlayer.state.playlist.medias;
            final mediaIndex = songs
                .indexWhere((element) => element.extras!["key"] == song?.key);
            final Media? media =
                mediaIndex != -1 ? songs[mediaIndex] : null;
            final isDownloaded = song != null &&
                media != null &&
                LocalMusicsData.isInstalled(audioId: song.audioId) &&
                (media.extras!["url"] as String).isUrl;

            if (isDownloading) {
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
            if (isDownloaded) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  musicManager.refreshSongs(
                      musicManager.audioDataManager.currentIndex!);
                },
              );
            }
            if (downloadable) {
              return IconButton(
                  onPressed: () {
                    HomeScreenMusicManager.download(song);
                  },
                  icon: const Icon(Icons.file_download));
            }
            if (song != null && song.isInstalled) {
              return const IconButton(
                // TODO: uninstall, delete
                onPressed: null,
                icon: Icon(Icons.file_download_done),
              );
            }
            return const IconButton(
                onPressed: null, icon: Icon(Icons.file_download));
          },
        );
      },
    );
  }
}
