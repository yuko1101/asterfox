import 'package:asterfox/screen/home_screen.dart';
import 'package:asterfox/theme/theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AsterfoxApp());
}

ValueNotifier<String> themeNotifier = ValueNotifier<String>("light");

class AsterfoxApp extends StatelessWidget {
  const AsterfoxApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        builder: (context, value, child) {

          return MaterialApp(
            title: 'Asterfox',
            theme: themes[value],
            home: const HomeScreen(),
          );
        },
        valueListenable: themeNotifier,
    );
  }
}
