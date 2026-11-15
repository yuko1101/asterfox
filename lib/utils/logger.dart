import 'package:flutter/foundation.dart';

final List<String> logs = [];

void log(dynamic string) {
  logs.add(string.toString());
  debugPrint(string.toString());
}
