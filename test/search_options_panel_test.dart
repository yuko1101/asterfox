import 'dart:io';

import 'package:asterfox/data/custom_colors.dart';
import 'package:asterfox/data/database.dart';
import 'package:asterfox/l10n/app_localizations.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:asterfox/widget/option_widgets/option_switch.dart';
import 'package:asterfox/widget/search/search_options.dart';
import 'package:asterfox/widget/search/search_options_panel.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory data;
  late AppDatabase db;

  setUpAll(() async {
    data = await Directory.systemTemp.createTemp('asterfox_options_data');
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

  Widget panel({
    SearchOptions options = const SearchOptions(),
    bool offline = true,
    ValueChanged<SearchOptions>? onOptionsChanged,
    ValueChanged<bool>? onOfflineChanged,
  }) {
    return MaterialApp(
      theme: AppTheme.themes[0],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SearchOptionsPanel(
          options: options,
          offline: offline,
          onOptionsChanged: onOptionsChanged ?? (_) {},
          onOfflineChanged: onOfflineChanged ?? (_) {},
        ),
      ),
    );
  }

  /// The switch that turns the offline search on and off.
  OptionSwitch offlineSwitch(WidgetTester tester) => tester
      .widgetList<OptionSwitch>(find.byType(OptionSwitch))
      .firstWhere((widget) => (widget.title as Text).data == 'Offline Search');

  testWidgets('the offline search is on by default', (tester) async {
    await tester.pumpWidget(panel(offline: true));
    await tester.pumpAndSettle();

    expect(offlineSwitch(tester).value, isTrue);
  });

  testWidgets('the titles of the stored songs options are shown',
      (tester) async {
    await tester.pumpWidget(panel(offline: true));
    await tester.pumpAndSettle();

    expect(find.text('Group by'), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Downloaded only'), findsOneWidget);
  });

  testWidgets('the stored songs options are hidden when YouTube is used',
      (tester) async {
    // A song fetched from YouTube has no playlists, no lyrics and no date it
    // was added, so none of these can be answered for it.
    await tester.pumpWidget(panel(offline: false));
    await tester.pumpAndSettle();

    expect(find.text('Group by'), findsNothing);
    expect(find.text('Sort by'), findsNothing);
    expect(find.text('Filter'), findsNothing);
    expect(offlineSwitch(tester).value, isFalse);
  });

  testWidgets('turning the offline search off is reported', (tester) async {
    bool? told;
    await tester.pumpWidget(panel(offline: true, onOfflineChanged: (value) {
      told = value;
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(told, isFalse);
  });

  testWidgets('choosing to group by artist is reported', (tester) async {
    SearchOptions? told;
    await tester.pumpWidget(panel(onOptionsChanged: (value) {
      told = value;
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Song Artist'));
    await tester.pumpAndSettle();

    expect(told?.grouping, SearchGrouping.artist);
  });

  testWidgets('turning on the lyrics filter keeps the other choices',
      (tester) async {
    SearchOptions? told;
    await tester.pumpWidget(panel(
      options: const SearchOptions().copyWith(grouping: SearchGrouping.artist),
      onOptionsChanged: (value) {
        told = value;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(told?.lyrics, SearchLyricsFilter.withLyrics);
    expect(told?.grouping, SearchGrouping.artist);
  });

  testWidgets('resetting is only offered once something is chosen',
      (tester) async {
    await tester.pumpWidget(panel());
    await tester.pumpAndSettle();
    expect(find.text('Reset'), findsNothing);

    await tester.pumpWidget(panel(
      options: const SearchOptions().copyWith(grouping: SearchGrouping.playlist),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Reset'), findsOneWidget);
  });
}
