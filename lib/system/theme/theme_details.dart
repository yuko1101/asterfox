import 'package:flutter/material.dart';

class ThemeDetails extends ThemeExtension<ThemeDetails> {
  ThemeDetails({
    required this.name,
  });
  final String name;

  @override
  ThemeExtension<ThemeDetails> copyWith({
    String? name,
  }) {
    return ThemeDetails(
      name: name ?? this.name,
    );
  }

  @override
  ThemeExtension<ThemeDetails> lerp(
      ThemeExtension<ThemeDetails>? other, double t) {
    return this;
  }
}
