import 'package:flutter/material.dart';

import '../../data/custom_colors.dart';
import '../../main.dart';
import '../../system/theme/theme.dart';
import '../option_widgets/option_switch.dart';
import 'search_options.dart';

/// How the stored songs of the search are grouped, filtered and ordered.
///
/// Every option here describes a stored song. A suggestion fetched from YouTube
/// has no playlists, no lyrics and no date it was added, so the YouTube results
/// below the stored ones are shown as they come back.
class SearchOptionsPanel extends StatefulWidget {
  const SearchOptionsPanel({
    required this.options,
    required this.onOptionsChanged,
    super.key,
  });

  final SearchOptions options;
  final ValueChanged<SearchOptions> onOptionsChanged;

  @override
  State<SearchOptionsPanel> createState() => _SearchOptionsPanelState();
}

class _SearchOptionsPanelState extends State<SearchOptionsPanel> {
  late SearchOptions options = widget.options;

  @override
  void didUpdateWidget(SearchOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The panel is rebuilt with new values by its owner, so it follows them
    // instead of keeping the ones it was first given.
    if (widget.options != oldWidget.options) options = widget.options;
  }

  void update(SearchOptions next) {
    setState(() => options = next);
    widget.onOptionsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(l10n.value.group_by),
        _choice<SearchGrouping>(
          labels: {
            SearchGrouping.none: l10n.value.group_none,
            SearchGrouping.playlist: l10n.value.playlist,
            SearchGrouping.artist: l10n.value.song_artist,
          },
          selected: options.grouping,
          onSelected: (value) => update(options.copyWith(grouping: value)),
        ),
        _heading(l10n.value.sort_by),
        _choice<SearchSort>(
          labels: {
            SearchSort.relevance: l10n.value.sort_relevance,
            SearchSort.addedNewest: l10n.value.sort_added_newest,
            SearchSort.addedOldest: l10n.value.sort_added_oldest,
            SearchSort.shuffled: l10n.value.sort_shuffled,
          },
          selected: options.sort,
          onSelected: (value) => update(options.copyWith(sort: value)),
        ),
        _heading(l10n.value.filter),
        OptionSwitch(
          title: Text(l10n.value.downloaded_only),
          value: options.state == SearchStateFilter.installed,
          onChanged: (_, to) => update(options.copyWith(
            state: to ? SearchStateFilter.installed : SearchStateFilter.all,
          )),
        ),
        OptionSwitch(
          title: Text(l10n.value.with_lyrics),
          value: options.lyrics == SearchLyricsFilter.withLyrics,
          onChanged: (_, to) => update(options.copyWith(
            lyrics:
                to ? SearchLyricsFilter.withLyrics : SearchLyricsFilter.all,
          )),
        ),
        if (!options.isDefault)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextButton.icon(
              onPressed: () => update(const SearchOptions()),
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.value.reset),
              style: TextButton.styleFrom(
                foregroundColor: CustomColors.getColor("accent"),
              ),
            ),
          ),
      ],
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).extraColors.secondary,
          ),
        ),
      );

  /// A row of choices, of which one is picked.
  ///
  /// `SegmentedButton` rather than a column of radios: the choices are short
  /// names meant to be seen side by side.
  Widget _choice<T extends Enum>({
    required Map<T, String> labels,
    required T selected,
    required ValueChanged<T> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SegmentedButton<T>(
        segments: [
          for (final entry in labels.entries)
            ButtonSegment<T>(
              value: entry.key,
              label: Text(
                entry.value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
        selected: {selected},
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
        ),
        onSelectionChanged: (selection) => onSelected(selection.first),
      ),
    );
  }
}
