import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class NotificationData {
  NotificationData({
    required this.title,
    this.progress
  });
  final Widget title;
  final Future<void> Function()? progress;

  final String id = const Uuid().v4();
}