import 'package:flutter/material.dart';

class ThemeOptions extends ThemeExtension<ThemeOptions> {
  ThemeOptions({
    required this.isShadowed,
  });
  final ShadowLevel isShadowed;

  @override
  ThemeExtension<ThemeOptions> copyWith({
      ShadowLevel? isShadowed,
  }) {
    return ThemeOptions(
      isShadowed: isShadowed ?? this.isShadowed,
    );
  }

  @override
  ThemeExtension<ThemeOptions> lerp(ThemeExtension<ThemeOptions>? other, double t) {
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
