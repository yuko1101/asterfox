import 'dart:io';

import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/database.dart';
import 'package:asterfox/l10n/app_localizations.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/widget/search/search_scope_button.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The button that switches the search between the stored songs and YouTube.
///
/// It is a button of its own rather than a switch inside the options, so the
/// scope can be changed in one press.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory data;
  late AppDatabase db;

  setUpAll(() async {
    data = await Directory.systemTemp.createTemp('asterfox_scope_button');
    localPath = data.path;
    tempPath = '${data.path}/temp';
  });

  tearDownAll(() async {
    if (data.existsSync()) await data.delete(recursive: true);
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase(File('${data.path}/asterfox.sqlite')));
    AppDatabase.setInstanceForTest(db);
    await CustomColors.init();
    l10n.value = lookupAppLocalizations(const Locale('en'));
  });

  tearDown(() async {
    AppDatabase.clearInstanceForTest();
    await db.close();
  });

  Future<void> pumpButton(
    WidgetTester tester, {
    required bool offline,
    ValueChanged<bool>? onChanged,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.themes[0],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: AppBar(
          actions: [
            SearchScopeButton(offline: offline, onChanged: onChanged ?? (_) {}),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the button names the scope it is searching', (tester) async {
    await pumpButton(tester, offline: true);
    expect(find.byTooltip('Offline Search'), findsOneWidget);

    await pumpButton(tester, offline: false);
    expect(find.byTooltip('YouTube Search'), findsOneWidget);
  });

  testWidgets('one press switches to the other scope', (tester) async {
    bool? told;
    await pumpButton(tester, offline: true, onChanged: (value) => told = value);

    await tester.tap(find.byType(SearchScopeButton));
    await tester.pumpAndSettle();

    expect(told, isFalse);
  });

  testWidgets('the button shows the scope now in effect', (tester) async {
    // The app bar is rebuilt by the search only when the query changes, so the
    // button carries its own state: it has to read as the scope the next
    // search will use, or pressing it looks like it did nothing.
    await pumpButton(tester, offline: true);

    await tester.tap(find.byType(SearchScopeButton));
    await tester.pumpAndSettle();

    expect(find.byTooltip('YouTube Search'), findsOneWidget);
    expect(find.byTooltip('Offline Search'), findsNothing);
  });

  testWidgets('pressing it again goes back', (tester) async {
    final told = <bool>[];
    await pumpButton(tester, offline: true, onChanged: told.add);

    await tester.tap(find.byType(SearchScopeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SearchScopeButton));
    await tester.pumpAndSettle();

    expect(told, [false, true]);
    expect(find.byTooltip('Offline Search'), findsOneWidget);
  });

  testWidgets('the icon tells the two scopes apart', (tester) async {
    await pumpButton(tester, offline: true);
    expect(find.byIcon(Icons.offline_pin_outlined), findsOneWidget);

    await pumpButton(tester, offline: false);
    expect(find.byIcon(Icons.youtube_searched_for), findsOneWidget);
  });
}
