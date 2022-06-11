import 'dart:convert';

import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/manager/audio_data_manager.dart';
import 'package:asterfox/widget/music_widgets/music_thumbnail.dart';
import 'package:asterfox/widget/playlist_widget.dart';
import 'package:colored_json/colored_json.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:asterfox/system/theme/theme.dart';

import '../widget/song_search.dart';

class DebugScreen extends BaseScreen {
  const DebugScreen() : super(
      screen: const DebugMainScreen(),
      appBar: const DebugAppBar(),
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
            Row(
              children: [
                IconButton(onPressed: () {
                    if (AppTheme.themeNotifier.value != "dark") {

                      AppTheme.setTheme("dark");
                    } else {
                      AppTheme.setTheme("light");
                      // showSearch(context: context, delegate: delegate);
                    }
                  }, icon: Theme.of(context).brightness == Brightness.dark ? const Icon(Icons.dark_mode) : const Icon(Icons.light_mode)),
                IconButton(onPressed: musicManager.previous, icon: const Icon(Icons.skip_previous)),
                IconButton(onPressed: musicManager.play, icon: const Icon(Icons.play_arrow)),
                IconButton(onPressed: musicManager.pause, icon: const Icon(Icons.pause)),
                IconButton(onPressed: musicManager.next, icon: const Icon(Icons.skip_next)),
                IconButton(onPressed: () {
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
                              LocalMusicsData.removeAllFromLocal(LocalMusicsData.getAll());
                              LocalMusicsData.saveData();
                            },
                          ),
                        ],
                      )
                  );
                }, icon: const Icon(Icons.delete)),
                IconButton(
                    onPressed: () {
                      showSearch(context: context, delegate: SongSearch());
                    },
                    icon: const Icon(Icons.search)
                )
              ],
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
                        linked: true,
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
                                    opacity: musicManager.audioDataManager.currentIndex == index ? 0.3 : 1.0,
                                    child: MusicImageWidget(songs[index].imageUrl)
                                  ),
                                  if (musicManager.audioDataManager.currentIndex == index) Center(
                                    child: SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: ValueListenableBuilder<PlayingState>(
                                        valueListenable: musicManager.playingStateNotifier,
                                        builder: (_, playingState, __) {
                                          if (playingState == PlayingState.playing) {
                                            return Image.asset("assets/images/playing.gif");
                                          } else {
                                            return const Icon(Icons.pause);
                                          }
                                        }
                                      )),
                                  ),

                                ]
                              ),
                            ),
                            onTap: () {
                              musicManager.seek(Duration.zero, index: index);
                            },
                          );
                        },
                    );
                  }
                );
              }
            ),
            ValueListenableBuilder<MusicData?>(
                valueListenable: musicManager.currentSongNotifier,
                builder: (_, song, __) {
                  if (song == null) {
                    return Container();
                  }
                  final String json = const JsonEncoder.withIndent("  ").convert(song.toJson());
                  return ColoredJson(
                    data: json,
                    intColor: Colors.orange,
                    doubleColor: Colors.red,
                    commaColor: Colors.grey,
                    squareBracketColor: Colors.grey,
                    colonColor: Colors.grey,
                    curlyBracketColor: Colors.purpleAccent,
                  );
                }
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