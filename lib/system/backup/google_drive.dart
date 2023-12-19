import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';

import '../../music/audio_source/music_data.dart';
import '../../utils/extension_utils.dart';
import 'backup_manager.dart';

class GoogleDriveBackupManager {
  static final accounts = <GoogleSignIn>[];

  static Future<void> login() async {
    final googleSignIn = GoogleSignIn(scopes: [
      DriveApi.driveAppdataScope,
    ]);
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception("Canceled by user.");
    }
    accounts.add(googleSignIn);
  }

  static Future<void> logout(GoogleSignIn account) async {
    await account.disconnect();
    accounts.remove(account);
  }

  static Future<void> logoutAll() async {
    for (final account in accounts) {
      await account.disconnect();
    }
    accounts.clear();
  }

  static Future<> getSong(MusicData musicData, BackupLocation backupLocation) async {
    final GoogleSignIn account;
    try {
      account = accounts.firstWhere((acc) => acc.currentUser?.email == backupLocation.accountEmail, orElse: () => throw Exception("Account not found."));
    } catch (e) {
      return null;
    }

    final driveApi = (await account.authenticatedClient())?.let((it) => DriveApi(it));
    if (driveApi == null) return null;

    // backup
    await driveApi.files.create(
      File()
        ..name = "${musicData.audioId}.mp3"
        ..parents = ["appDataFolder", "music"],
      uploadMedia: Media(
        
      ),
    );


  }
}
