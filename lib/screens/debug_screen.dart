import 'dart:convert';
import 'dart:math';

import 'package:asterfox/screens/home_screen.dart';
import 'package:asterfox/widget/toast/toast_manager.dart';
import 'package:colored_json/colored_json.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screens/scaffold_screen.dart';
import 'package:easy_app/utils/in_app_notification/notification_data.dart';
import 'package:flutter/material.dart';

import '../data/local_musics_data.dart';
import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/manager/audio_data_manager.dart';
import '../widget/music_widgets/music_thumbnail.dart';
import '../widget/playlist_widget.dart';
import '../widget/search/song_search.dart';

class DebugScreen extends ScaffoldScreen {
  const DebugScreen({
    Key? key,
  }) : super(
          body: const DebugMainScreen(),
          appBar: const DebugAppBar(),
          key: key,
        );
}

class DebugMainScreen extends StatelessWidget {
  const DebugMainScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.bug_report),
                    onPressed: () async {
                      await ToastManager.showSimpleToast(
                        icon: const Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                        msg: const Text(
                          "ログインしました",
                          style: TextStyle(fontSize: 20),
                        ),
                        context: context,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("保存された曲の全削除"),
                          content: const Text("本当に削除しますか？"),
                          actions: [
                            TextButton(
                              child: const Text("キャンセル"),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text("OK"),
                              onPressed: () {
                                Navigator.of(context).pop();
                                LocalMusicsData.deleteSongs(
                                    LocalMusicsData.getAll(isTemporary: true)
                                        .map((e) => e.audioId)
                                        .toList());
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      showSearch(context: context, delegate: SongSearch());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.discount),
                    onPressed: () {
                      print(MusicData.getCreated());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      final songsToInstall =
                          LocalMusicsData.getAll(isTemporary: true)
                              .where((song) => !song.isInstalled);
                      int sizeInBytes = 0;
                      bool isAccurate = true;
                      for (final song in songsToInstall) {
                        if (song.size == null) {
                          isAccurate = false;
                        } else {
                          sizeInBytes += song.size!;
                        }
                      }
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("全曲インストール"),
                          content: Text(
                              "ダウンロードに必要な容量: ${isAccurate ? "" : "最低"}${formatBytes(sizeInBytes, 1)} (${songsToInstall.length}曲)"),
                          actions: [
                            TextButton(
                              child: const Text("キャンセル"),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: const Text("ダウンロード"),
                              onPressed: () {
                                final ValueNotifier<int> downloaded =
                                    ValueNotifier(0);
                                final futures = songsToInstall
                                    .map((song) => () async {
                                          await song.install();
                                          downloaded.value =
                                              downloaded.value + 1;
                                        }())
                                    .toList();
                                HomeScreen.homeNotification.pushNotification(
                                  NotificationData(
                                    child: ValueListenableBuilder(
                                      valueListenable: downloaded,
                                      builder: (_, count, __) => Text(
                                        "インストール中: $count/${futures.length}",
                                      ),
                                    ),
                                    progress: Future.wait(futures),
                                  ),
                                );
                                Navigator.pop(context);
                                EasyApp.pushPage(context, HomeScreen());
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: () {
                      final songsToUninstall =
                          LocalMusicsData.getAll(isTemporary: true)
                              .where((song) => song.isInstalled);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("インストール済みの曲の全削除"),
                          content: Text("${songsToUninstall.length}曲を削除します"),
                          actions: [
                            TextButton(
                              child: const Text("キャンセル"),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: const Text("削除"),
                              onPressed: () {
                                final ValueNotifier<int> deleted =
                                    ValueNotifier(0);
                                final futures = songsToUninstall
                                    .map((song) => () async {
                                          await song.unistall();
                                          deleted.value = deleted.value + 1;
                                        }())
                                    .toList();
                                HomeScreen.homeNotification.pushNotification(
                                  NotificationData(
                                    child: ValueListenableBuilder(
                                      valueListenable: deleted,
                                      builder: (_, count, __) => Text(
                                        "アンインストール中: $count/${futures.length}",
                                      ),
                                    ),
                                    progress: Future.wait(futures),
                                  ),
                                );
                                Navigator.pop(context);
                                EasyApp.pushPage(context, HomeScreen());
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<MusicData?>(
              valueListenable: musicManager.currentSongNotifier,
              builder: (_, song, __) {
                return ValueListenableBuilder<List<MusicData>>(
                  valueListenable: musicManager.shuffledPlaylistNotifier,
                  builder: (_, songs, __) {
                    return PlaylistWidget(
                      songs: songs,
                      playing: song,
                      isLinked: true,
                      songWidgetBuilder: (context, index) {
                        return ListTile(
                          key: Key(songs[index].key),
                          title: Text(songs[index].title),
                          // title: Text("${songs[index].title}  shuffled: ${musicManager.audioDataManager.shuffledPlaylist.indexWhere((element) => element.key == songs[index].key)}, normal: ${musicManager.audioDataManager.playlist.indexWhere((element) => element.key == songs[index].key)}, ${musicManager.audioDataManager.shuffledIndices}"),
                          subtitle: Text(songs[index].author),
                          leading: SizedBox(
                            height: 50,
                            width: 70,
                            child: Stack(
                              children: [
                                Opacity(
                                  opacity: musicManager
                                              .audioDataManager.currentIndex ==
                                          index
                                      ? 0.3
                                      : 1.0,
                                  child:
                                      MusicImageWidget(songs[index].imageUrl),
                                ),
                                if (musicManager
                                        .audioDataManager.currentIndex ==
                                    index)
                                  Center(
                                    child: SizedBox(
                                      height: 25,
                                      width: 25,
                                      child:
                                          ValueListenableBuilder<PlayingState>(
                                        valueListenable:
                                            musicManager.playingStateNotifier,
                                        builder: (_, playingState, __) {
                                          if (playingState ==
                                              PlayingState.playing) {
                                            return Image.asset(
                                                "assets/images/playing.gif");
                                          } else {
                                            return const Icon(Icons.pause);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          onTap: () {
                            musicManager.seek(Duration.zero, index: index);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            ValueListenableBuilder<MusicData?>(
              valueListenable: musicManager.currentSongNotifier,
              builder: (_, song, __) {
                if (song == null) {
                  return Container();
                }
                final String json =
                    const JsonEncoder.withIndent("  ").convert(song.toJson());
                return ColoredJson(
                  data: json,
                  intColor: Colors.orange,
                  doubleColor: Colors.red,
                  commaColor: Colors.grey,
                  squareBracketColor: Colors.grey,
                  colonColor: Colors.grey,
                  curlyBracketColor: Colors.purpleAccent,
                );
              },
            )
          ],
        ),
      ),
    );
  }

  static String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) +
        ' ' +
        suffixes[i];
  }
}

class DebugAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DebugAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Debug'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          EasyApp.popPage(context);
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
