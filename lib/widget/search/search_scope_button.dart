import 'package:flutter/material.dart';

import '../../main.dart';
import '../../system/theme/theme.dart';

/// The button that switches the search between the songs stored on this device
/// and YouTube.
///
/// It is a button of its own rather than a switch among the options, so the
/// scope is one press away instead of three: open the options, find the switch,
/// change it.
///
/// It keeps the scope it is showing because an AppBar built by a `SearchDelegate`
/// is only rebuilt when the query changes. Without its own state, pressing it
/// would change what the next search looks at while the button itself went on
/// showing the old scope, as if nothing had happened.
class SearchScopeButton extends StatefulWidget {
  const SearchScopeButton({
    required this.offline,
    required this.onChanged,
    super.key,
  });

  /// Whether the search looks at the stored songs, or at YouTube.
  final bool offline;

  final ValueChanged<bool> onChanged;

  @override
  State<SearchScopeButton> createState() => _SearchScopeButtonState();
}

class _SearchScopeButtonState extends State<SearchScopeButton> {
  late bool offline = widget.offline;

  @override
  void didUpdateWidget(SearchScopeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.offline != oldWidget.offline) offline = widget.offline;
  }

  void toggle() {
    final next = !offline;
    setState(() => offline = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(offline ? Icons.offline_pin_outlined : Icons.youtube_searched_for),
      color: Theme.of(context).extraColors.primary,
      tooltip: offline ? l10n.value.offline_search : l10n.value.youtube_search,
      onPressed: toggle,
    );
  }
}
