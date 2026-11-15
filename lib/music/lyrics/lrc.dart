/// A line of synced lyrics: [text] is sung from [start] until the next line.
class SyncedLyricLine {
  const SyncedLyricLine(this.start, this.text);

  final Duration start;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is SyncedLyricLine && other.start == start && other.text == text;

  @override
  int get hashCode => Object.hash(start, text);

  @override
  String toString() => "SyncedLyricLine($start, $text)";
}

/// Reads and writes lyrics in the LRC format (`[mm:ss.xx] text`).
///
/// Synced lyrics are stored in `MusicData.lyrics` as LRC, so that a song keeps
/// one lyrics string whether or not it has timing, and plain lyrics stay as
/// they were. The parser follows pear-desktop's synced-lyrics plugin.
class Lrc {
  static final _timestamp = RegExp(r"^\[(\d+):(\d+)(?:[.:](\d+))?\]");
  static final _tag = RegExp(r"^\[(\w+):\s*(.+?)\s*\]$");
  static final _word = RegExp(r"<\d+:\d+[.:]\d+>\s*");

  /// The timed lines of [text], sorted by time, or an empty list when [text]
  /// has none (plain lyrics).
  static List<SyncedLyricLine> parse(String text) {
    final lines = <SyncedLyricLine>[];
    var offset = 0;

    for (var line in text.split("\n")) {
      line = line.trim();
      if (!line.startsWith("[")) continue;

      final starts = <int>[];
      RegExpMatch? match;
      while ((match = _timestamp.firstMatch(line)) != null) {
        final minutes = int.parse(match!.group(1)!);
        final seconds = int.parse(match.group(2)!);
        // "5" is half a second, "05" is 50 ms and "005" is 5 ms.
        final fraction = (match.group(3) ?? "0").padRight(3, "0");
        final millis = int.parse(fraction.substring(0, 3));
        starts.add(minutes * 60000 + seconds * 1000 + millis);
        line = line.substring(match.end);
      }

      if (starts.isEmpty) {
        final tag = _tag.firstMatch(line);
        if (tag != null && tag.group(1) == "offset") {
          offset = int.tryParse(tag.group(2)!) ?? 0;
        }
        continue;
      }

      final lineText = line.replaceAll(_word, "").trim();
      for (final start in starts) {
        lines.add(SyncedLyricLine(Duration(milliseconds: start), lineText));
      }
    }

    lines.sort((a, b) => a.start.compareTo(b.start));
    // A positive offset shows the lyrics sooner.
    if (offset == 0) return lines;
    return [
      for (final line in lines)
        SyncedLyricLine(
          Duration(
              milliseconds:
                  (line.start.inMilliseconds - offset).clamp(0, 1 << 52)),
          line.text,
        )
    ];
  }

  /// The `[offset:]` of [text] in milliseconds: how much sooner its lines are
  /// shown than their timestamps say. 0 when it has none.
  static int offsetOf(String text) {
    var offset = 0;
    for (final line in text.split("\n")) {
      final tag = _tag.firstMatch(line.trim());
      if (tag != null && tag.group(1) == "offset") {
        offset = int.tryParse(tag.group(2)!) ?? 0;
      }
    }
    return offset;
  }

  /// [text] shown [offset] milliseconds sooner than its timestamps say, by
  /// rewriting its `[offset:]` tag. The timestamps stay as they were fetched,
  /// so going back to 0 gives the fetched timing again.
  static String withOffset(String text, int offset) {
    final lines = text.split("\n").where((line) {
      final tag = _tag.firstMatch(line.trim());
      return tag == null || tag.group(1) != "offset";
    });
    return [
      if (offset != 0) "[offset:${offset > 0 ? "+" : ""}$offset]",
      ...lines,
    ].join("\n");
  }

  /// Whether [text] holds timed lyrics rather than plain ones.
  static bool isSynced(String text) => parse(text).isNotEmpty;

  /// [lines] as LRC text.
  static String format(List<SyncedLyricLine> lines) {
    return lines
        .map((line) => "[${_time(line.start)}] ${line.text}")
        .join("\n");
  }

  /// The words of [text] without the timing, for showing or searching them.
  static String toPlainText(String text) {
    if (!text.contains("[")) return text;
    final lines = parse(text);
    if (lines.isEmpty) return text;
    return lines.map((line) => line.text).join("\n").trim();
  }

  /// The index of the line being sung at [position], or -1 before the first.
  static int currentLineIndex(List<SyncedLyricLine> lines, Duration position) {
    var low = 0;
    var high = lines.length - 1;
    var result = -1;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      if (lines[middle].start <= position) {
        result = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return result;
  }

  static String _time(Duration time) {
    final minutes = time.inMinutes.toString().padLeft(2, "0");
    final seconds = (time.inSeconds % 60).toString().padLeft(2, "0");
    final centis =
        ((time.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, "0");
    return "$minutes:$seconds.$centis";
  }
}
