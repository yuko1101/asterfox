import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../main.dart';
import '../../music/lyrics/lrc.dart';
import '../../music/manager/audio_data_manager.dart';
import '../../music/music_data/music_data.dart';

/// Timed lyrics that follow playback: the line being sung is highlighted and
/// kept in the middle, and tapping a line plays the song from there.
class SyncedLyricsView extends StatelessWidget {
  const SyncedLyricsView({super.key, required this.song, required this.lines});

  final MusicData song;
  final List<SyncedLyricLine> lines;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.progressNotifier,
      builder: (context, state, _) {
        final playing = state.currentSong?.audioId == song.audioId;
        return SyncedLyricsList(
          lines: lines,
          position: playing ? state.position : null,
          onTapLine: playing ? (line) => musicManager.seek(line.start) : null,
        );
      },
    );
  }
}

/// [lines] with the one sung at [position] highlighted and scrolled into the
/// middle. A null [position] means the song isn't playing, so no line is.
class SyncedLyricsList extends StatefulWidget {
  const SyncedLyricsList({
    super.key,
    required this.lines,
    required this.position,
    this.onTapLine,
  });

  final List<SyncedLyricLine> lines;
  final Duration? position;
  final void Function(SyncedLyricLine line)? onTapLine;

  /// How long auto-scrolling waits after the user scrolled by hand.
  static const userScrollPause = Duration(seconds: 3);

  @override
  State<SyncedLyricsList> createState() => _SyncedLyricsListState();
}

class _SyncedLyricsListState extends State<SyncedLyricsList> {
  late List<GlobalKey> _keys;
  int _scrolledTo = -1;
  DateTime _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _resumeTimer;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.lines.length, (_) => GlobalKey());
    _scheduleScroll(animate: false);
  }

  @override
  void didUpdateWidget(SyncedLyricsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.length != widget.lines.length) {
      _keys = List.generate(widget.lines.length, (_) => GlobalKey());
      _scrolledTo = -1;
    }
    _scheduleScroll(animate: true);
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    super.dispose();
  }

  int get _current => widget.position == null
      ? -1
      : Lrc.currentLineIndex(widget.lines, widget.position!);

  void _scheduleScroll({required bool animate, bool force = false}) {
    final index = _current;
    if (index < 0 || (index == _scrolledTo && !force)) return;
    if (DateTime.now().difference(_userScrolledAt) <
        SyncedLyricsList.userScrollPause) {
      return;
    }
    _scrolledTo = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _keys[index].currentContext;
      if (context == null || !context.mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: Curves.easeOut,
      );
    });
  }

  /// Plays from [line], and follows it at once even after a manual scroll.
  void _tap(SyncedLyricLine line) {
    _resumeTimer?.cancel();
    _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);
    widget.onTapLine!(line);
  }

  bool _onScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.idle) return false;
    _userScrolledAt = DateTime.now();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(SyncedLyricsList.userScrollPause, () {
      if (mounted) _scheduleScroll(animate: true, force: true);
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _current;
    final base = theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final height = MediaQuery.of(context).size.height;

    return NotificationListener<UserScrollNotification>(
      onNotification: _onScroll,
      // Its own Material, so that a tapped line ripples above the sheet's
      // background colour instead of under it.
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: height * 0.2, horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < widget.lines.length; i++)
                _line(context, i, i == current, i < current, base, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, int index, bool isCurrent, bool isPast,
      TextStyle base, ThemeData theme) {
    final line = widget.lines[index];
    final color = isCurrent
        ? theme.colorScheme.primary
        : theme.textTheme.bodyMedium?.color
            ?.withValues(alpha: isPast ? 0.4 : 0.65);
    return InkWell(
      key: _keys[index],
      onTap: widget.onTapLine == null ? null : () => _tap(line),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: base.copyWith(
            color: color,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: (base.fontSize ?? 16) * (isCurrent ? 1.15 : 1),
          ),
          textAlign: TextAlign.center,
          child: Text(line.text.isEmpty ? "♪" : line.text),
        ),
      ),
    );
  }
}

/// Shifts timed lyrics by hand when they run ahead of or behind the song.
///
/// [offset] is the LRC offset in milliseconds: positive shows the lyrics
/// sooner. The buttons read as moving the lyrics, not the offset.
class LyricsOffsetBar extends StatelessWidget {
  const LyricsOffsetBar({
    super.key,
    required this.offset,
    required this.onChanged,
  });

  final int offset;
  final ValueChanged<int> onChanged;

  static const smallStep = 100;
  static const largeStep = 500;

  static String describe(int offset) {
    if (offset == 0) return l10n.value.lyrics_as_fetched;
    final seconds = (offset.abs() / 1000).toStringAsFixed(1);
    return offset > 0
        ? l10n.value.lyrics_earlier(seconds)
        : l10n.value.lyrics_later(seconds);
  }

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, int by, String tooltip) => IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: () => onChanged(offset + by),
        );
    String seconds(int millis) => (millis / 1000).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.value.lyrics_timing,
              style: Theme.of(context).textTheme.labelMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              step(Icons.keyboard_double_arrow_left, largeStep,
                  l10n.value.lyrics_earlier(seconds(largeStep))),
              step(Icons.chevron_left, smallStep,
                  l10n.value.lyrics_earlier(seconds(smallStep))),
              SizedBox(
                width: 120,
                child: Text(
                  describe(offset),
                  key: const ValueKey("lyrics-offset"),
                  textAlign: TextAlign.center,
                ),
              ),
              step(Icons.chevron_right, -smallStep,
                  l10n.value.lyrics_later(seconds(smallStep))),
              step(Icons.keyboard_double_arrow_right, -largeStep,
                  l10n.value.lyrics_later(seconds(largeStep))),
              IconButton(
                icon: const Icon(Icons.restart_alt),
                tooltip: l10n.value.lyrics_timing_reset,
                onPressed: offset == 0 ? null : () => onChanged(0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
