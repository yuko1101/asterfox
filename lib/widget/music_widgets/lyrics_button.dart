import 'dart:async';

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

  /// Opens the lyrics panel. It shows the lyrics of the song that is playing,
  /// which [song] is when the lyrics are opened from the player.
  static void showLyrics(MusicData song, BuildContext context) {
    LyricsPanel.open();
  }
}

/// The lyrics of the song that is playing, laid over the playlist rather than
/// over the whole screen, so that the player below them can still be used.
///
/// It follows the song: playing the next one shows that one's lyrics.
class LyricsPanel extends StatelessWidget {
  const LyricsPanel({super.key});

  /// Whether the panel is shown.
  static final ValueNotifier<bool> shown = ValueNotifier(false);

  /// Counts the openings, so that lyrics found or edited since the panel was
  /// built are read again.
  static final ValueNotifier<int> _openings = ValueNotifier(0);

  static void open() {
    _openings.value++;
    shown.value = true;
  }

  static void close() => shown.value = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: shown,
      builder: (context, isShown, _) {
        if (!isShown) return const SizedBox.shrink();
        return ValueListenableBuilder<AudioState>(
          valueListenable: musicManager.audioStateManager.currentSongNotifier,
          builder: (context, state, _) =>
              LyricsPanelBody(song: state.currentSong),
        );
      },
    );
  }
}

/// The open lyrics panel for [song]. The back button closes it.
class LyricsPanelBody extends StatelessWidget {
  const LyricsPanelBody({super.key, required this.song});

  final MusicData? song;

  @override
  Widget build(BuildContext context) {
    final song = this.song;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) LyricsPanel.close();
      },
      child: ValueListenableBuilder<int>(
        valueListenable: LyricsPanel._openings,
        builder: (context, openings, _) => song == null
            ? LyricsSheet.empty(onClose: LyricsPanel.close)
            : LyricsSheet(
                // A new song, or lyrics found since, start a new sheet.
                key: ValueKey("${song.audioId}#$openings"),
                song: song,
                onClose: LyricsPanel.close,
              ),
      ),
    );
  }
}

/// A song's lyrics. Timed ones follow playback, and their timing can be
/// shifted by hand from the button in the app bar. A song without lyrics
/// offers to search for them.
class LyricsSheet extends StatefulWidget {
  const LyricsSheet(
      {super.key, required MusicData this.song, required this.onClose});

  /// The sheet when no song is playing.
  const LyricsSheet.empty({super.key, required this.onClose}) : song = null;

  final MusicData? song;
  final VoidCallback onClose;

  /// How long the timing waits to be saved after the last change, so that
  /// tapping a step button several times saves once.
  static const saveDelay = Duration(milliseconds: 800);

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  MusicData? get song => widget.song;

  late String _lyrics = song?.lyrics ?? "";
  late List<SyncedLyricLine> _lines = Lrc.parse(_lyrics);
  bool _adjusting = false;
  Timer? _saveTimer;

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      _save();
    }
    super.dispose();
  }

  void _setOffset(int offset) {
    setState(() {
      _lyrics = Lrc.withOffset(_lyrics, offset);
      _lines = Lrc.parse(_lyrics);
    });
    _saveTimer?.cancel();
    _saveTimer = Timer(LyricsSheet.saveDelay, _save);
  }

  void _save() => LyricsFinder.applyLyrics(song!, _lyrics, true);

  void _search() => FindLyricsDialog(song!).show(context);

  @override
  Widget build(BuildContext context) {
    final song = this.song;
    final synced = _lines.isNotEmpty;
    final Widget body;
    if (synced) {
      body = SyncedLyricsView(song: song!, lines: _lines);
    } else if (_lyrics.trim().isNotEmpty) {
      body = SingleChildScrollView(
        child: Text(
          _lyrics,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      body = Center(
        child: song == null
            ? null
            : TextButton.icon(
                icon: const Icon(Icons.search),
                label: Text(l10n.value.search_lyrics),
                onPressed: _search,
              ),
      );
    }

    return Material(
      child: Column(
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            title: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Text(
                song?.title ?? "",
                style: TextStyle(
                  color: Theme.of(context).extraColors.secondary,
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.expand_more),
              onPressed: widget.onClose,
              tooltip: l10n.value.close,
            ),
            actions: [
              if (synced)
                IconButton(
                  icon: const Icon(Icons.av_timer),
                  tooltip: l10n.value.lyrics_timing,
                  isSelected: _adjusting,
                  onPressed: () => setState(() => _adjusting = !_adjusting),
                ),
              if (song != null)
                IconButton(
                  icon: const Icon(Icons.edit_note),
                  tooltip: l10n.value.search_lyrics,
                  onPressed: _search,
                )
            ],
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: body,
            ),
          ),
          if (synced && _adjusting)
            LyricsOffsetBar(
              offset: Lrc.offsetOf(_lyrics),
              onChanged: _setOffset,
            ),
        ],
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
