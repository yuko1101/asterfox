import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class OS extends StatelessWidget {
  final Widget? android;
  final Widget? iOS;
  final Widget? windows;
  final Widget? macOS;
  final Widget? linux;
  final Widget? fuchsia;
  final Widget? web;
  final Widget? unknown;

  const OS({
    Key? key,
    this.android,
    this.iOS,
    this.windows,
    this.macOS,
    this.linux,
    this.fuchsia,
    this.web,
    this.unknown,
  }) : super(key: key);

// This size work fine on my design, maybe you need some customization depends on your design

  // This isMobile, isTablet, isDesktop helep us later
  static bool isMobile() =>
      Platform.isAndroid || Platform.isIOS;

  static bool isDesktopOrLaptop() =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  static bool isWeb() => kIsWeb;

  static OSType getOS() {
    if (kIsWeb) return OSType.web;
    if (Platform.isAndroid) return OSType.android;
    if (Platform.isIOS) return OSType.iOS;
    if (Platform.isWindows) return OSType.windows;
    if (Platform.isMacOS) return OSType.macOS;
    if (Platform.isLinux) return OSType.linux;
    if (Platform.isFuchsia) return OSType.fuchsia;
    return OSType.unknown;
  }

  @override
  Widget build(BuildContext context) {
    final dummy = Container(height: 0, width: 0);
    switch (getOS()) {
      case OSType.android:
        return android ?? dummy;
      case OSType.iOS:
        return iOS ?? dummy;
      case OSType.windows:
        return windows ?? dummy;
      case OSType.macOS:
        return macOS ?? dummy;
      case OSType.linux:
        return linux ?? dummy;
      case OSType.fuchsia:
        return fuchsia ?? dummy;
      case OSType.web:
        return web ?? dummy;
      case OSType.unknown:
        return unknown ?? dummy;
    }
  }
}

enum OSType {
  android,
  iOS,
  windows,
  macOS,
  linux,
  fuchsia,
  web,
  unknown
}