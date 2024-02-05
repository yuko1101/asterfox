import 'package:flutter/material.dart';

class ThemeDetails extends ThemeExtension<ThemeDetails> {
  ThemeDetails({
    required this.name,
    required this.icon,
  });
  final String name;
  final IconData icon;

  @override
  ThemeExtension<ThemeDetails> copyWith({
    String? name,
    IconData? icon,
  }) {
    return ThemeDetails(
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }

  @override
  ThemeExtension<ThemeDetails> lerp(
      ThemeExtension<ThemeDetails>? other, double t) {
    return this;
  }
}
