import 'dart:io';

import 'package:flutter/foundation.dart';

class OS {
  static bool get isWeb => kIsWeb;
  static bool get isIOS => !isWeb && Platform.isIOS;
  static bool get isAndroid => !isWeb && Platform.isAndroid;
  static bool get isMacOS => !isWeb && Platform.isMacOS;
  static bool get isWindows => !isWeb && Platform.isWindows;
  static bool get isLinux => !isWeb && Platform.isLinux;
  static bool get isFuchsia => !isWeb && Platform.isFuchsia;
}
