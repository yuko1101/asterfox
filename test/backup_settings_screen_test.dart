import 'dart:io';

import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/database.dart';
import 'package:asterfox/l10n/app_localizations.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/screens/settings/backup_settings_screen.dart';
import 'package:asterfox/system/theme/theme.dart';
// `isNull` and `isNotNull` are the matchers here, not drift's query helpers.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_file_picker.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory data;
  late AppDatabase db;

  // `localPath` and `tempPath` are `late final` in main.dart, so they can only
  // be written once for the whole run; the database is what is rebuilt per
  // test.
  setUpAll(() async {
    data = await Directory.systemTemp.createTemp('asterfox_screen_data');
    localPath = data.path;
    tempPath = '${data.path}/temp';
    await Directory(tempPath).create(recursive: true);
  });

  tearDownAll(() async {
    if (data.existsSync()) await data.delete(recursive: true);
  });

  setUp(() async {
    // main.dart's globals, which the screen and its dialogs read, and the
    // database behind them. The screen cannot be exercised without these.
    await Directory('${data.path}/music/songA').create(recursive: true);
    await File('${data.path}/music/songA/audio').writeAsBytes([1, 2, 3]);
    await File('${data.path}/music/songA/info.json').writeAsString('{}');

    db = AppDatabase(NativeDatabase(File('${data.path}/asterfox.sqlite')));
    AppDatabase.setInstanceForTest(db);
    await CustomColors.init();

    l10n.value = lookupAppLocalizations(const Locale('en'));
  });

  tearDown(() async {
    AppDatabase.clearInstanceForTest();
    await db.close();
  });

  Widget app() => MaterialApp(
        theme: AppTheme.themes[0],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BackupSettingsScreen(),
      );

  testWidgets('the backup screen shows an export and a restore action',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Backup and restore'), findsWidgets);
    expect(find.text('Export data'), findsOneWidget);
    expect(find.text('Restore a backup'), findsOneWidget);
  });

  testWidgets('restoring asks for confirmation first', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore a backup'));
    await tester.pumpAndSettle();

    // The dialog is up, and the file dialog has not run yet (it cannot in a
    // test, so reaching it would throw instead).
    expect(find.textContaining('replaced by the backup'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('exporting shows a progress bar, not just a spinner',
      (tester) async {
    FilePicker.platform = FakeFilePicker(savePath: '${data.path}/out.zip');
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export data'));
    // One frame: the dialog is up and the packing has started.
    await tester.pump();

    // A bar with a value is what makes the wait visible. An indeterminate
    // indicator (value == null) would be a spinner that never moves, which is
    // what this screen used to show. The progress the value follows is checked
    // in backup_service_test.dart, because file I/O does not advance under the
    // test clock.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.value, isNotNull);
    expect(indicator.value, 0.0);
  });
}
