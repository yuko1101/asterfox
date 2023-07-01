import 'dart:convert';
import 'dart:math';

import 'package:colored_json/colored_json.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screens/scaffold_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:http/http.dart' as http;

import '../data/local_musics_data.dart';
import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../system/firebase/cloud_firestore.dart';
import '../utils/async_utils.dart';
import '../utils/result.dart';
import '../widget/process_notifications/process_notification_widget.dart';
import '../widget/search/song_search.dart';
import '../widget/toast/toast_manager.dart';
import 'home_screen.dart';

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
                                final asyncCore =
                                    AsyncCore<Result<void>>(limit: 5);
                                final ValueNotifier<int> downloaded =
                                    ValueNotifier(0);
                                final ValueNotifier<List<ResultFailedReason>>
                                    errorListNotifier = ValueNotifier([]);
                                final futures = songsToInstall
                                    .map((song) => () async {
                                          final result =
                                              await asyncCore.run(song.install);
                                          if (result.status ==
                                              ResultStatus.failed) {
                                            errorListNotifier.value =
                                                errorListNotifier.value.toList()
                                                  ..add(result.getReason());
                                          }
                                          downloaded.value =
                                              downloaded.value + 1;
                                        }())
                                    .toList();
                                HomeScreen.processNotificationList.push(
                                  ProcessNotificationData(
                                    title: ValueListenableBuilder(
                                      valueListenable: downloaded,
                                      builder: (_, count, __) => Text(
                                        "インストール中: $count/${futures.length}",
                                      ),
                                    ),
                                    maxProgress: futures.length,
                                    progressListenable: downloaded,
                                    errorListNotifier: errorListNotifier,
                                    icon: const Icon(Icons.download),
                                    future: Future.wait(futures),
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
                                          await song.uninstall();
                                          deleted.value = deleted.value + 1;
                                        }())
                                    .toList();
                                HomeScreen.processNotificationList.push(
                                  ProcessNotificationData(
                                    title: ValueListenableBuilder(
                                      valueListenable: deleted,
                                      builder: (_, count, __) => Text(
                                        "アンインストール中: $count/${futures.length}",
                                      ),
                                    ),
                                    icon: const Icon(Icons.file_download_off),
                                    future: Future.wait(futures),
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
                    icon: const Icon(Icons.upload_file),
                    onPressed: () async {
                      final ClipboardData? cdata =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      final String? data = cdata?.text;
                      if (data == null || data.isEmpty) {
                        ToastManager.showSimpleToast(
                          msg: const Text("クリップボードが空です"),
                          context: context,
                        );
                        return;
                      }

                      final res = await http.get(Uri.parse(data));
                      final content =
                          const Utf8Decoder().convert(res.bodyBytes);

                      late final Map<String, dynamic> json;
                      try {
                        json = jsonDecode(content);
                      } catch (e) {
                        ToastManager.showSimpleToast(
                          msg: const Text("JSONのパース中にエラーが発生しました"),
                          context: context,
                        );
                        return;
                      }

                      ToastManager.showSimpleToast(
                        msg: const Text("インポート中"),
                        context: context,
                      );
                      try {
                        await CloudFirestoreManager.importData(json);
                      } catch (e) {
                        ToastManager.showSimpleToast(
                          msg: const Text("インポート中にエラーが発生しました"),
                          context: context,
                        );
                        return;
                      }
                      ToastManager.showSimpleToast(
                        msg: const Text("インポートが完了しました"),
                        context: context,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.window),
                    onPressed: () async {
                      if (await FlutterOverlayWindow.isActive()) {
                        await FlutterOverlayWindow.closeOverlay();
                        return;
                      }
                      await FlutterOverlayWindow.showOverlay(
                        enableDrag: true,
                        overlayTitle: "Asterfox Music",
                        overlayContent: "Overlay Enabled",
                        flag: OverlayFlag.defaultFlag,
                        visibility: NotificationVisibility.visibilityPublic,
                        positionGravity: PositionGravity.none,
                        height: 300,
                        width: 300,
                      );
                    },
                  ),
                ],
              ),
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
