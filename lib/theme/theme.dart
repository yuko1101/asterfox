import 'package:asterfox/util/color_util.dart';
import 'package:flutter/material.dart';


ThemeData light = ThemeData(
  primarySwatch: getMaterialColor(Colors.white),
  textTheme: TextTheme(
    headline2: TextStyle(color: getMaterialColor(Colors.black54))
  )
);

ThemeData dark = ThemeData.dark().copyWith(
    appBarTheme: AppBarTheme(color: getMaterialColor(Colors.black87)),
    backgroundColor: getGrey(20),
    scaffoldBackgroundColor: getGrey(20),
    dialogBackgroundColor: getGrey(20),
    textTheme: TextTheme(
        headline2: TextStyle(color: getMaterialColor(Colors.white54, baseColor: Colors.black))
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


