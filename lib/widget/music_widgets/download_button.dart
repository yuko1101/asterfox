import 'package:asterfox/config/custom_colors.dart';
import 'package:asterfox/config/local_musics_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/music_downloader.dart';
import 'package:asterfox/screen/screens/home_screen.dart';
import 'package:asterfox/util/in_app_notification/notification_data.dart';
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
                    downloadProgress[song!.key] = ValueNotifier<int>(0);
                    homeNotification.pushNotification(
                      NotificationData(
                          child: ValueListenableBuilder<int>(
                            valueListenable: downloadProgress[song.key]!,
                            builder: (_, percentage, __) => Column(
                              children: [
                                const Text("ダウンロード中"),
                                SizedBox(
                                  width: 100,
                                  child: LinearProgressIndicator(
                                    minHeight: 8,
                                    value: percentage / 100,
                                    color: CustomColors.getColor("accent"),
                                    backgroundColor: CustomColors.getColor("accent").withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          progress: () async => await MusicDownloader.download(song)
                      ),
                    );
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
