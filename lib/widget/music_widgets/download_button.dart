import 'package:asterfox/config/local_musics_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/music_downloader.dart';
import 'package:asterfox/system/home_screen_music_manager.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';


class DownloadButton extends StatelessWidget {
  const DownloadButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _httpRegex = RegExp(r'^https?:\/\/.+$');

    return ValueListenableBuilder<MusicData?>(
      valueListenable: musicManager.currentSongNotifier,
      builder: (_, song, __) {
        return ValueListenableBuilder<List<String>>(
          valueListenable: downloading,
          builder: (_, downloadingSongs, __) {
            print("download changed!");
            final downloadable = song != null && !song.isLocal;
            final isDownloading = downloadingSongs.contains(song?.key);

            final List<IndexedAudioSource?> songs = musicManager.audioHandler.audioPlayer.sequence ?? [];
            final audioSourceIndex = songs.indexWhere((element) => element != null && element.tag["key"] == song?.key);
            final IndexedAudioSource? audioSource = audioSourceIndex != -1 ? songs[audioSourceIndex] : null;
            final isDownloaded = song != null && audioSource != null && LocalMusicsData.getById(song.audioId) != null && _httpRegex.hasMatch(audioSource.tag["url"]);

            if (isDownloading) {
              return ValueListenableBuilder<int>(
                  valueListenable: downloadProgress[song!.key]!,
                  builder: (_, percentage, __) => Container(
                    height: 24,
                    width: 24,
                    margin: const EdgeInsets.only(right: 12, left: 12),
                    child: Tooltip(
                      child: const CircularProgressIndicator(),
                      message: "ローカルに保存中: $percentage%",
                    )
                  )
              );
            }
            if (isDownloaded) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  musicManager.refreshSongs(musicManager.audioDataManager.currentIndex!);
                },
              );
            }
            if (downloadable) {
              return IconButton(
                  onPressed: () {
                    HomeScreenMusicManager.download(song!);
                  },
                  icon: const Icon(Icons.file_download)
              );
            }
            if (song != null && song.isLocal) {
              return const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.file_download_done)
              );
            }
            return const IconButton(
                onPressed: null,
                icon: Icon(Icons.file_download)
            );

          }
        );
      }
    );
  }
}
