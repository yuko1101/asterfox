import 'package:asterfox/l10n/app_localizations.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/screens/settings/backup_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The screen reads `l10n` from main.dart, which an app run fills in.
  setUp(() {
    l10n.value = lookupAppLocalizations(const Locale('en'));
  });

  testWidgets('the backup screen shows an export and a restore action',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BackupSettingsScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Backup and restore'), findsWidgets);
    expect(find.text('Export data'), findsOneWidget);
    expect(find.text('Restore a backup'), findsOneWidget);
  });

  testWidgets('restoring asks for confirmation first', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BackupSettingsScreen(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore a backup'));
    await tester.pumpAndSettle();

    // The dialog is up, and the file dialog has not run yet (it cannot in a
    // test, so reaching it would throw instead).
    expect(find.textContaining('replaced by the backup'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
