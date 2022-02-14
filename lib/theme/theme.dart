import 'package:asterfox/util/color_util.dart';
import 'package:flutter/material.dart';


ThemeData light = ThemeData(
  primarySwatch: getMaterialColor(Colors.white),
  textTheme: TextTheme(
    headline1: const TextStyle(color: Colors.black), // bright

    headline3: TextStyle(color: getGrey(45)), // middle
  )
);

ThemeData dark = ThemeData(
    brightness: Brightness.dark,

    appBarTheme: AppBarTheme(color: getMaterialColor(Colors.black87)),
    backgroundColor: getGrey(20),
    scaffoldBackgroundColor: getGrey(20),
    dialogBackgroundColor: getGrey(20),
    textTheme: TextTheme(
        headline3: TextStyle(color: getGrey(200)), // middle
        headline4: TextStyle(color: getGrey(100))
    )
);

Map<String, ThemeData> themes = {
  "light": light,
  "dark": dark
};

// ThemeColor backgroundColor = ThemeColor(
//   light: Colors.white,
//   dark: getGrey(20)
// );
//
// ThemeColor appBarColor = ThemeColor(
//   light: Colors.white,
//   dark: Colors.black87
// );
//
// ThemeColor textColor = ThemeColor(
//     light: Colors.black,
//     dark: Colors.white
// );
//
// ThemeColor greyTextColor = ThemeColor(
//     light: Colors.black54,
//     dark: Colors.white54
// );
//


// ThemeColor textColor2 = ThemeColor(
//     light: Colors.,
//     dark: Colors.white
// );


