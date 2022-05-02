import 'package:asterfox/config/custom_colors.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/music_downloader.dart';
import 'package:asterfox/screen/screens/home_screen.dart';
import 'package:asterfox/util/in_app_notification/notification_data.dart';
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
            final downloadable = song != null && !song.isLocal;
            final isDownloading = downloadingSongs.contains(song?.key);
            if (isDownloading) {
              return ValueListenableBuilder<int>(
                  valueListenable: downloadProgress[song!.key!]!,
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
            return IconButton(
                onPressed: downloadable ? () {
                  downloadProgress[song!.key!] = ValueNotifier<int>(0);
                  homeNotification.pushNotification(
                    NotificationData(
                      child: ValueListenableBuilder<int>(
                        valueListenable: downloadProgress[song.key!]!,
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
                } : null,
                icon: const Icon(Icons.file_download)
            );
          }
        );
      }
    );
  }
}
