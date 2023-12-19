import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../main.dart';
import '../../music/audio_source/music_data.dart';
import '../../music/lyrics_finder.dart';
import '../../music/manager/notifiers/audio_state_notifier.dart';
import '../../system/theme/theme.dart';

class LyricsButton extends StatelessWidget {
  const LyricsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
        valueListenable: musicManager.audioStateManager.currentSongNotifier,
        builder: (context, audioState, _) {
          final song = audioState.currentSong;
          return IconButton(
            icon: Icon(
              Icons.lyrics_outlined,
              shadows: [
                BoxShadow(
                  color: Theme.of(context).backgroundColor,
                  offset: const Offset(0, 0),
                  blurRadius: 10,
                ),
              ],
            ),
            onPressed: song == null
                ? null
                : () {
                    if (song.lyrics.isNotEmpty) {
                      showLyrics(song, context);
                      return;
                    }
                    final FindLyricsDialog findLyricsDialog =
                        FindLyricsDialog(song);
                    showDialog(
                        context: context, builder: findLyricsDialog.pages[0]);
                  },
          );
        });
  }

  static void showLyrics(MusicData song, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Material(
        child: Column(
          children: [
            AppBar(
              title: Row(
                children: [
                  Text(Language.getText("lyrics")),
                  const SizedBox(width: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        song.title,
                        style: TextStyle(
                          color: Theme.of(context).extraColors.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.expand_more),
                onPressed: () {
                  Navigator.pop(context);
                },
                tooltip: Language.getText("close"),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_note),
                  onPressed: () {
                    Navigator.pop(context);
                    final FindLyricsDialog findLyricsDialog =
                        FindLyricsDialog(song);
                    showDialog(
                        context: context, builder: findLyricsDialog.pages[0]);
                  },
                )
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  color: Theme.of(context).backgroundColor,
                  child: Text(
                    song.lyrics,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FindLyricsDialog {
  FindLyricsDialog(this.song) {
    pages = [
      // Song Title
      (context) {
        final textEditingController = TextEditingController();
        textEditingController.text = songTitle;
        return AlertDialog(
          title: Text(Language.getText("song_title")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText.rich(
                TextSpan(text: song.title),
                toolbarOptions: const ToolbarOptions(
                    copy: false, cut: false, paste: false, selectAll: false),
                onSelectionChanged: (selection, cause) {
                  final selected = selection.isCollapsed
                      ? ""
                      : song.title
                          .substring(selection.start, selection.end)
                          .trim();
                  textEditingController.text = selected;
                  songTitle = selected;
                },
              ),
              TextField(
                controller: textEditingController,
                onChanged: (input) {
                  songTitle = input.trim();
                },
                onSubmitted: (input) {
                  songTitle = input.trim();
                  goTo(currentPage + 1, context);
                },
              ),
            ],
          ),
          actions: [
            cancelButton(context),
            fromClipboardButton(context),
            nextButton(context),
          ],
        );
      },
      // Song Artist
      (context) {
        final textEditingController = TextEditingController();
        textEditingController.text = songArtist;
        final displayText = "${song.title}\n${song.author}";
        return AlertDialog(
          title: Text(Language.getText("song_artist")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText.rich(
                TextSpan(text: displayText),
                toolbarOptions: const ToolbarOptions(
                    copy: false, cut: false, paste: false, selectAll: false),
                onSelectionChanged: (selection, cause) {
                  final selected = selection.isCollapsed
                      ? ""
                      : displayText
                          .substring(selection.start, selection.end)
                          .trim();
                  textEditingController.text = selected;
                  songArtist = selected;
                },
              ),
              TextField(
                controller: textEditingController,
                onChanged: (input) {
                  songArtist = input.trim();
                },
                onSubmitted: (input) async {
                  songArtist = input.trim();
                  await finish(context);
                },
              ),
            ],
          ),
          actions: [
            cancelButton(context),
            previousButton(context),
            TextButton(
              child: Text(Language.getText("finish")),
              onPressed: () async => await finish(context),
            )
          ],
        );
      }
    ];
  }
  final MusicData song;
  late List<Widget Function(BuildContext)> pages;

  int currentPage = 0;

  String songTitle = "";
  String songArtist = "";
  String? lyrics;

  void goTo(int page, BuildContext context) {
    if (page > pages.length - 1 || page < 0) {
      throw Exception("Page index out of range");
    }
    currentPage = page;
    Navigator.pop(context);
    showDialog(context: context, builder: pages[page]);
  }

  Future<void> finish(BuildContext context) async {
    // TODO: make better (like progress indicator)
    lyrics ??= await LyricsFinder.search(songTitle, songArtist);
    if (lyrics == null || lyrics!.isEmpty) {
      Fluttertoast.showToast(msg: Language.getText("lyrics_not_found"));
      Navigator.pop(context);
      return;
    }
    await LyricsFinder.applyLyrics(song, lyrics!, true);
    Navigator.pop(context);
    LyricsButton.showLyrics(song, context);
  }

  TextButton cancelButton(BuildContext context) => TextButton(
        child: Text(Language.getText("cancel")),
        onPressed: () {
          Navigator.pop(context);
        },
      );
  TextButton previousButton(BuildContext context) => TextButton(
        child: Text(Language.getText("previous")),
        onPressed: () {
          goTo(currentPage - 1, context);
        },
      );
  TextButton nextButton(BuildContext context) => TextButton(
        child: Text(Language.getText("next")),
        onPressed: () {
          goTo(currentPage + 1, context);
        },
      );

  TextButton fromClipboardButton(BuildContext context) => TextButton(
        child: Text(Language.getText("from_clipboard")),
        onPressed: () async {
          final clipboardData = await Clipboard.getData("text/plain");
          if (clipboardData == null) {
            Fluttertoast.showToast(
                msg: Language.getText("no_text_in_clipboard"));
            return;
          }
          final text = clipboardData.text;
          if (text == null) {
            Fluttertoast.showToast(
                msg: Language.getText("no_text_in_clipboard"));
            return;
          }
          lyrics = text;
          finish(context);
        },
      );
}
