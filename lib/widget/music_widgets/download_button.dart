import 'package:asterfox/music/utils/music_url_utils.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/local_musics_data.dart';
import '../../main.dart';
import '../../music/audio_source/music_data.dart';
import '../../music/music_downloader.dart';
import '../../system/home_screen_music_manager.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MusicData?>(
      valueListenable: musicManager.currentSongNotifier,
      builder: (_, song, __) {
        return ValueListenableBuilder<List<String>>(
          valueListenable: DownloadManager.downloadingNotifier,
          builder: (_, downloadingSongs, __) {
            print("download changed!");
            final downloadable = song != null && !song.isInstalled;
            final isDownloading = downloadingSongs.contains(song?.audioId);

            final List<IndexedAudioSource?> songs =
                musicManager.audioHandler.audioPlayer.sequence ?? [];
            final audioSourceIndex = songs.indexWhere((element) =>
                element != null && element.tag["key"] == song?.key);
            final IndexedAudioSource? audioSource =
                audioSourceIndex != -1 ? songs[audioSourceIndex] : null;
            final isDownloaded = song != null &&
                audioSource != null &&
                LocalMusicsData.isInstalled(audioId: song.audioId) &&
                (audioSource.tag["url"] as String).isUrl;

            if (isDownloading) {
              return Container(
                height: 24,
                width: 24,
                margin: const EdgeInsets.only(right: 12, left: 12),
                child: Tooltip(
                  child: const CircularProgressIndicator(),
                  message: Language.getText("saving"),
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
