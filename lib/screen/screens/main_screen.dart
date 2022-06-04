import 'package:asterfox/screen/base_screen.dart';
import 'package:asterfox/screen/drawer.dart';
import 'package:asterfox/screen/page_manager.dart';
import 'package:asterfox/utils/responsive.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BaseScreen>(
        valueListenable: PageManager.screenNotifier,
        builder: (_, baseScreen, __) {
          if (Responsive.isDesktop(context)) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SideMenu(),
                    Expanded(child: baseScreen.screen),
                    baseScreen.endDrawer ?? const SizedBox(width: 0, height: 0)
                  ],
              ),
            );
          }
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: baseScreen.appBar,
            body: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: baseScreen.footer != null ? [Expanded(child: baseScreen.screen), baseScreen.footer!] : [Expanded(child: baseScreen.screen)],
            ),
            drawer: const SideMenu(),
            endDrawer: baseScreen.endDrawer,
          );
        }
    );
  }
}
