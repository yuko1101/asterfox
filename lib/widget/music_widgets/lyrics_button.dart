import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../main.dart';
import '../../music/manager/audio_data_manager.dart';
import '../../music/music_data/music_data.dart';
import '../../music/lyrics/lrc.dart';
import '../../music/lyrics_finder.dart';
import '../../system/theme/theme.dart';
import '../loading_dialog.dart';
import 'synced_lyrics_view.dart';

class LyricsButton extends StatelessWidget {
  const LyricsButton({super.key});

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
                  color: Theme.of(context).scaffoldBackgroundColor,
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
                    FindLyricsDialog(song).show(context);
                  },
          );
        });
  }

  static void showLyrics(MusicData song, BuildContext context) {
    final syncedLines = Lrc.parse(song.lyrics);
    showModalBottomSheet(
      context: context,
      builder: (context) => Material(
        child: Column(
          children: [
            AppBar(
              title: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Text(
                  song.title,
                  style: TextStyle(
                    color: Theme.of(context).extraColors.secondary,
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.expand_more),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                tooltip: l10n.value.close,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_note),
                  onPressed: () {
                    final navigator = Navigator.of(context)..pop();
                    FindLyricsDialog(song).show(navigator.context);
                  },
                )
              ],
            ),
            Flexible(
              child: Container(
                width: MediaQuery.of(context).size.width,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: syncedLines.isNotEmpty
                    ? SyncedLyricsView(song: song, lines: syncedLines)
                    : SingleChildScrollView(
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
          title: Text(l10n.value.song_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText.rich(
                TextSpan(text: song.title),
                contextMenuBuilder: (context, editableTextState) =>
                    const SizedBox(),
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
          title: Text(l10n.value.song_artist),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText.rich(
                TextSpan(text: displayText),
                contextMenuBuilder: (context, editableTextState) =>
                    const SizedBox(),
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
              child: Text(l10n.value.finish),
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

  /// The navigator the pages are shown on. A page is replaced by the next one,
  /// so the context of a page is gone once it has been left, and this is what
  /// stays.
  late NavigatorState _navigator;

  void show(BuildContext context) {
    _navigator = Navigator.of(context);
    currentPage = 0;
    showDialog(context: context, builder: pages[0]);
  }

  void goTo(int page, BuildContext context) {
    if (page < 0 || page >= pages.length) return;
    currentPage = page;
    _navigator.pop();
    showDialog(context: _navigator.context, builder: pages[page]);
  }

  bool _finishing = false;

  Future<void> finish(BuildContext context) async {
    if (_finishing) return;
    _finishing = true;
    final page = ModalRoute.of(context);
    try {
      var found = lyrics;
      if (found == null) {
        final search = LyricsFinder.search(songTitle, songArtist, song: song);
        await LoadingDialog.showLoading(
            context: _navigator.context, future: search);
        found = await search;
      }
      if (found.isEmpty) {
        Fluttertoast.showToast(msg: l10n.value.lyrics_not_found);
        return;
      }
      await LyricsFinder.applyLyrics(song, found, true);
      _close(page);
      if (_navigator.mounted) LyricsButton.showLyrics(song, _navigator.context);
    } on Exception {
      Fluttertoast.showToast(msg: l10n.value.lyrics_not_found);
    } finally {
      _close(page);
      _finishing = false;
    }
  }

  /// Closes [page] if it is still open, and nothing else.
  void _close(Route? page) {
    if (page == null || !page.isActive) return;
    if (page.isCurrent) {
      _navigator.pop();
    } else {
      _navigator.removeRoute(page);
    }
  }

  TextButton cancelButton(BuildContext context) => TextButton(
        child: Text(l10n.value.cancel),
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
  TextButton previousButton(BuildContext context) => TextButton(
        child: Text(l10n.value.previous),
        onPressed: () {
          goTo(currentPage - 1, context);
        },
      );
  TextButton nextButton(BuildContext context) => TextButton(
        child: Text(l10n.value.next),
        onPressed: () {
          goTo(currentPage + 1, context);
        },
      );

  TextButton fromClipboardButton(BuildContext context) => TextButton(
        child: Text(l10n.value.from_clipboard),
        onPressed: () async {
          final clipboardData = await Clipboard.getData("text/plain");
          if (clipboardData == null) {
            Fluttertoast.showToast(msg: l10n.value.no_text_in_clipboard);
            return;
          }
          final text = clipboardData.text;
          if (text == null) {
            Fluttertoast.showToast(msg: l10n.value.no_text_in_clipboard);
            return;
          }
          lyrics = text;
          if (context.mounted) finish(context);
        },
      );
}
