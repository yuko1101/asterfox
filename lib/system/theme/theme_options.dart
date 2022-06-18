import 'package:flutter/material.dart';

class ThemeOptions extends ThemeExtension<ThemeOptions> {
  ThemeOptions({
    required this.shadow,
  });
  final ShadowLevel shadow;

  @override
  ThemeExtension<ThemeOptions> copyWith({
    ShadowLevel? shadow,
  }) {
    return ThemeOptions(
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  ThemeExtension<ThemeOptions> lerp(
      ThemeExtension<ThemeOptions>? other, double t) {
    return this;
  }
}

enum ShadowLevel {
  none,
  low,
  medium,
  high,
}

extension ShadowLevelExtension on ShadowLevel {
  int get level => index;
}
