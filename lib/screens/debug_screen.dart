import 'dart:convert';

import 'package:asterfox/system/firebase/cloud_firestore.dart';
import 'package:colored_json/colored_json.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screens/scaffold_screen.dart';
import 'package:flutter/material.dart';

import '../data/local_musics_data.dart';
import '../main.dart';
import '../music/audio_source/music_data.dart';
import '../music/manager/audio_data_manager.dart';
import '../system/theme/theme.dart';
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
                    icon: Theme.of(context).brightness == Brightness.dark
                        ? const Icon(Icons.dark_mode)
                        : const Icon(Icons.light_mode),
                    onPressed: () {
                      if (AppTheme.themeNotifier.value != "dark") {
                        AppTheme.setTheme("dark");
                      } else {
                        AppTheme.setTheme("light");
                        // showSearch(context: context, delegate: delegate);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: musicManager.previous,
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: musicManager.play,
                  ),
                  IconButton(
                    icon: const Icon(Icons.pause),
                    onPressed: musicManager.pause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: musicManager.next,
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
                                LocalMusicsData.removeAllFromLocal(
                                    LocalMusicsData.getAll(isTemporary: true));
                                LocalMusicsData.saveData();
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
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () async {
                      LocalMusicsData.clean();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.data_object),
                    onPressed: () async {
                      final data = await CloudFirestoreManager.getUserData();
                      print(data);
                    },
                  )
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
