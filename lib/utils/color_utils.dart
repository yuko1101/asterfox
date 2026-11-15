import 'package:flutter/material.dart';

Color getGrey(int white) {
  return Color.fromARGB(255, white, white, white);
}

/// A material color of a single shade: [color] laid over [baseColor], so that a
/// translucent color is shown as the pale color it looks like.
MaterialColor getMaterialColor(Color color, {Color baseColor = Colors.white}) {
  final blend = Color.alphaBlend(color, baseColor);
  return MaterialColor(
    blend.toARGB32(),
    {
      for (final shade in [50, 100, 200, 300, 400, 500, 600, 700, 800, 900])
        shade: blend
    },
  );
}
