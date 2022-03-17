import 'package:asterfox/main.dart';
import 'package:asterfox/screen/base_screen.dart';
import 'package:flutter/material.dart';

import '../../util/responsive.dart';
import '../drawer.dart';
import 'home_screen.dart';

ValueNotifier<BaseScreen> screenNotifier = ValueNotifier<BaseScreen>(HomeScreen());

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BaseScreen>(
        valueListenable: screenNotifier,
        builder: (_, baseScreen, __) {
          if (Responsive.isDesktop(context)) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: Row(children: [const SideMenu(), Expanded(child: baseScreen.screen,), baseScreen.endDrawer ?? const SizedBox(width: 0, height: 0)], mainAxisAlignment: MainAxisAlignment.start),
            );
          }
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: baseScreen.appBar,
            body: Column(
              children: baseScreen.footer != null ? [Expanded(child: baseScreen.screen), baseScreen.footer!] : [Expanded(child: baseScreen.screen)],
              mainAxisAlignment: MainAxisAlignment.end,
            ),
            drawer: const SideMenu(),
            endDrawer: baseScreen.endDrawer,
          );
        }
    );
  }
}
