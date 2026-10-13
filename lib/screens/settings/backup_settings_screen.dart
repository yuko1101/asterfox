import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../main.dart';
import '../../system/backup/backup_manager.dart';
import '../../system/backup/backup_service.dart';
import '../../utils/os.dart';
import '../../widget/loading_dialog.dart';
import '../../widget/screen/scaffold_screen.dart';
import '../../widget/toast/toast_manager.dart';

class BackupSettingsScreen extends ScaffoldScreen {
  const BackupSettingsScreen({super.key});

  @override
  PreferredSizeWidget appBar(BuildContext context) => const _AppBar();

  @override
  Widget body(BuildContext context) => const _BackupAndRestore();
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(l10n.value.backup_and_restore),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.value.go_back,
      ),
    );
  }
}

class _BackupAndRestore extends StatefulWidget {
  const _BackupAndRestore();

  @override
  State<_BackupAndRestore> createState() => _BackupAndRestoreState();
}

class _BackupAndRestoreState extends State<_BackupAndRestore> {
  BackupService? _service;
  BackupService get service => _service ??= BackupService();

  /// A backup holds the database file and the stored music of this device, and
  /// is written through the file dialogs, so it is only available where the app
  /// keeps files on the device.
  bool get isAvailable => !OS.isWeb;

  Future<void> _export() async {
    String? error;
    String? path;
    // Packing a large library takes a while, and the zip is written before any
    // dialog opens, so the progress of it is shown.
    final progress = ValueNotifier<int>(0);
    await LoadingDialog.showLoading(
      context: context,
      percentageNotifier: progress,
      future: () async {
        try {
          path = await service.exportToFile(onProgress: (percent) {
            progress.value = percent;
          });
        } catch (e) {
          // The save dialog is provided by the system, and can fail on its
          // own (no file manager, a denied permission). Report it rather than
          // let it escape, which would leave the progress dialog up.
          error = e.toString();
        }
      }(),
    );
    progress.dispose();
    if (!mounted) return;

    if (error != null) return _showError(l10n.value.export_data, error!);
    ToastManager.showSimpleToast(
      msg: Text(path == null ? l10n.value.cancelled : l10n.value.exported),
      icon: Icon(
        path == null ? Icons.cancel_outlined : Icons.check_circle_outline,
        color: path == null ? null : Colors.green,
      ),
    );
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.value.restore_backup),
        content: Text(l10n.value.restore_backup_confirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.value.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.value.restore),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    String? error;
    var restored = false;
    await LoadingDialog.showLoading(
      context: context,
      future: () async {
        try {
          restored = await service.importFromFile();
        } on BackupException catch (e) {
          error = e.message;
        } catch (e) {
          // The open dialog is provided by the system and can fail on its own.
          error = e.toString();
        }
      }(),
    );
    if (!mounted) return;

    if (error != null) return _showError(l10n.value.restore_backup, error!);
    if (!restored) return;

    // The database file was swapped, and the app holds the old one open.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.value.restart_required),
        content: Text(l10n.value.restart_to_apply_backup),
        actions: [
          TextButton(
            onPressed: () => exitApp(),
            child: Text(l10n.value.ok),
          ),
        ],
      ),
    );
  }

  /// Tells the user that [action] did not work and why.
  Future<void> _showError(String action, String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${l10n.value.failed}: $action"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.value.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      sections: [
        SettingsSection(
          title: Text(l10n.value.backup_and_restore),
          tiles: [
            SettingsTile.navigation(
              title: Text(l10n.value.export_data),
              description: Text(l10n.value.export_data_description),
              leading: const Icon(Icons.archive_outlined),
              enabled: isAvailable,
              onPressed: (_) => _export(),
            ),
            SettingsTile.navigation(
              title: Text(l10n.value.restore_backup),
              description: Text(l10n.value.restore_backup_description),
              leading: const Icon(Icons.settings_backup_restore),
              enabled: isAvailable,
              onPressed: (_) => _import(),
            ),
          ],
        ),
      ],
    );
  }
}
