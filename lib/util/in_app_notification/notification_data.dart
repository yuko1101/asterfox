import 'package:uuid/uuid.dart';

class NotificationData {
  NotificationData({
    required this.title
  });
  final String title;
  final String id = const Uuid().v4();
}