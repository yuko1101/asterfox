import 'package:flutter/material.dart';

class OptionSwitch extends StatefulWidget {
  const OptionSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.tileColor,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.contentPadding,
    this.secondary,
    this.selected = false,
    this.autofocus = false,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.shape,
    this.selectedTileColor,
    this.visualDensity,
    this.focusNode,
    this.enableFeedback,
    this.hoverColor,
  });

  /// Whether this switch is checked.
  ///
  /// This property must not be null.
  final bool value;

  final void Function(bool from, bool to) onChanged;

  /// The color to use when this switch is on.
  ///
  /// Defaults to accent color of the current [Theme].
  final Color? activeColor;

  /// The color to use on the track when this switch is on.
  ///
  /// Defaults to [ThemeData.toggleableActiveColor] with the opacity set at 50%.
  ///
  /// Ignored if created with [SwitchListTile.adaptive].
  final Color? activeTrackColor;

  /// The color to use on the thumb when this switch is off.
  ///
  /// Defaults to the colors described in the Material design specification.
  ///
  /// Ignored if created with [SwitchListTile.adaptive].
  final Color? inactiveThumbColor;

  /// The color to use on the track when this switch is off.
  ///
  /// Defaults to the colors described in the Material design specification.
  ///
  /// Ignored if created with [SwitchListTile.adaptive].
  final Color? inactiveTrackColor;

  /// {@macro flutter.material.ListTile.tileColor}
  final Color? tileColor;

  /// An image to use on the thumb of this switch when the switch is on.
  final ImageProvider? activeThumbImage;

  /// An image to use on the thumb of this switch when the switch is off.
  ///
  /// Ignored if created with [SwitchListTile.adaptive].
  final ImageProvider? inactiveThumbImage;

  /// The primary content of the list tile.
  ///
  /// Typically a [Text] widget.
  final Widget? title;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// A widget to display on the opposite side of the tile from the switch.
  ///
  /// Typically an [Icon] widget.
  final Widget? secondary;

  /// Whether this list tile is intended to display three lines of text.
  ///
  /// If false, the list tile is treated as having one line if the subtitle is
  /// null and treated as having two lines if the subtitle is non-null.
  final bool isThreeLine;

  /// Whether this list tile is part of a vertically dense list.
  ///
  /// If this property is null then its value is based on [ListTileThemeData.dense].
  final bool? dense;

  /// The tile's internal padding.
  ///
  /// Insets a [SwitchListTile]'s contents: its [title], [subtitle],
  /// [secondary], and [Switch] widgets.
  ///
  /// If null, [ListTile]'s default of `EdgeInsets.symmetric(horizontal: 16.0)`
  /// is used.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether to render icons and text in the [activeColor].
  ///
  /// No effort is made to automatically coordinate the [selected] state and the
  /// [value] state. To have the list tile appear selected when the switch is
  /// on, pass the same value to both.
  ///
  /// Normally, this property is left to its default value, false.
  final bool selected;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Defines the position of control and [secondary], relative to text.
  ///
  /// By default, the value of `controlAffinity` is [ListTileControlAffinity.platform].
  final ListTileControlAffinity controlAffinity;

  /// {@macro flutter.material.ListTile.shape}
  final ShapeBorder? shape;

  /// If non-null, defines the background color when [SwitchListTile.selected] is true.
  final Color? selectedTileColor;

  /// Defines how compact the list tile's layout will be.
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  final VisualDensity? visualDensity;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.material.ListTile.enableFeedback}
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  /// The color for the tile's [Material] when a pointer is hovering over it.
  final Color? hoverColor;

  @override
  State<OptionSwitch> createState() => OptionSwitchState();
}

class OptionSwitchState extends State<OptionSwitch> {
  late bool currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      activeColor: widget.activeColor,
      activeThumbImage: widget.activeThumbImage,
      activeTrackColor: widget.activeTrackColor,
      autofocus: widget.autofocus,
      contentPadding: widget.contentPadding,
      controlAffinity: widget.controlAffinity,
      dense: widget.dense,
      enableFeedback: widget.enableFeedback,
      focusNode: widget.focusNode,
      hoverColor: widget.hoverColor,
      inactiveThumbColor: widget.inactiveThumbColor,
      inactiveThumbImage: widget.inactiveThumbImage,
      inactiveTrackColor: widget.inactiveTrackColor,
      isThreeLine: widget.isThreeLine,
      key: widget.key,
      secondary: widget.secondary,
      selected: widget.selected,
      selectedTileColor: widget.selectedTileColor,
      shape: widget.shape,
      subtitle: widget.subtitle,
      tileColor: widget.tileColor,
      visualDensity: widget.visualDensity,
      title: widget.title,
      value: currentValue,
      onChanged: (value) => setState(() {
        final from = currentValue;
        currentValue = value;
        widget.onChanged(from, value);
      }),
    );
  }
}
