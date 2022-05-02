import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class NotificationData {
  NotificationData({
    required this.child,
    this.progress
  });
  final Widget child;
  final Future<void> Function()? progress;

  final String id = const Uuid().v4();
}