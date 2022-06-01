import 'package:flutter/material.dart';

class ExtraColors extends ThemeExtension<ExtraColors> {
  ExtraColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.quaternary,

    required this.themeColor,
  });
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color quaternary;

  final Color themeColor;

  @override
  ThemeExtension<ExtraColors> copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? quaternary,
    Color? oppose,
  }) {
    return ExtraColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      quaternary: quaternary ?? this.quaternary,
      themeColor: oppose ?? this.themeColor,
    );
  }

  @override
  ThemeExtension<ExtraColors> lerp(ThemeExtension<ExtraColors>? other, double t) {
    if (other is! ExtraColors) {
      return this;
    }
    return copyWith(
      primary: Color.lerp(primary, other.primary, t),
      secondary: Color.lerp(secondary, other.secondary, t),
      tertiary: Color.lerp(tertiary, other.tertiary, t),
      quaternary: Color.lerp(quaternary, other.quaternary, t),
      oppose: Color.lerp(themeColor, other.themeColor, t),
    );
  }



}