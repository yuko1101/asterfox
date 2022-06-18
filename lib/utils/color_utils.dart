import 'package:flutter/material.dart';

Color getGrey(int white) {
  return Color.fromARGB(255, white, white, white);
}

//アルファブレンド https://ja.wikipedia.org/wiki/%E3%82%A2%E3%83%AB%E3%83%95%E3%82%A1%E3%83%96%E3%83%AC%E3%83%B3%E3%83%89
MaterialColor getMaterialColor(Color color, {Color baseColor = Colors.white}) {
  final blend =
      color.alpha == 255 ? color : _convertToPaleColor(color, baseColor);
  return MaterialColor(
    blend.value,
    <int, Color>{
      50: blend,
      100: blend,
      200: blend,
      300: blend,
      400: blend,
      500: blend,
      600: blend,
      700: blend,
      800: blend,
      900: blend,
    },
  );
}

Color _convertToPaleColor(Color color, Color base) {
  return Color.fromARGB(
      ((color.alpha / 255 + base.alpha / 255 * (1 - color.alpha / 255)) * 255)
          .toInt(),
      _compositeColor(color.red, base.red, color.alpha),
      _compositeColor(color.green, base.green, color.alpha),
      _compositeColor(color.blue, base.blue, color.alpha));
}

int _compositeColor(int code, int baseCode, int alpha) {
  final opacity = alpha / 255;
  return (code * opacity + baseCode * (1 - opacity)).toInt();
}
