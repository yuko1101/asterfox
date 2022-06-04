import 'package:asterfox/screen/base_screen.dart';
import 'package:asterfox/screen/screens/home_screen.dart';
import 'package:flutter/material.dart';

class PageManager {

  static List<BaseScreen> pages = [];
  static ValueNotifier<BaseScreen> screenNotifier = ValueNotifier<BaseScreen>(HomeScreen());

  static bool goBack(BuildContext context) {
    if (screenNotifier.value is HomeScreen) return false;
    if (screenNotifier.value.previousPage != null) {
      pages.clear();
      screenNotifier.value = screenNotifier.value.previousPage!;
    } else {
      if (pages.length < 2) {
        screenNotifier.value = HomeScreen();
      } else {
        pages.removeLast();
        screenNotifier.value = pages.removeLast();
      }
    }
    return false;
  }

  static void pushPage(BuildContext context, BaseScreen page, {close = false}) {
    if (close) Navigator.pop(context); //close SideMenu
    screenNotifier.value = page;
  }
}