import 'package:asterfox/screen/base_screen.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class DebugScreen extends BaseScreen {
  const DebugScreen() : super(
      screen: const DebugMainScreen(),
  );
}

class DebugMainScreen extends StatelessWidget {
  const DebugMainScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          IconButton(onPressed: () {
              if (themeNotifier.value != "dark") {

                themeNotifier.value = "dark";
              } else {
                themeNotifier.value = "light";
                // showSearch(context: context, delegate: delegate);
              }
            }, icon: Theme.of(context).brightness == Brightness.dark ? const Icon(Icons.dark_mode) : const Icon(Icons.light_mode))
        ],
      ),
    );
  }


}
