import 'package:asterfox/widget/process_notifications/process_notification_list.dart';
import 'package:asterfox/widget/process_notifications/process_notification_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a throwing future still leaves the running list', () async {
    final list = ProcessNotificationList();

    final data = ProcessNotificationData(
      title: const Text('t'),
      future: Future<void>.error(Exception('boom')),
    );

    await expectLater(list.push(data), throwsA(isA<Exception>()));

    expect(list.notificationsNotifier.value, isEmpty);
    expect(list.erroredProcessList.value, isEmpty);
  });

  test('a successful future leaves the running list', () async {
    final list = ProcessNotificationList();

    await list.push(ProcessNotificationData(
      title: const Text('t'),
      future: Future<void>.value(),
    ));

    expect(list.notificationsNotifier.value, isEmpty);
  });
}
