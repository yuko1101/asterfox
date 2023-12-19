import '../../music/audio_source/music_data.dart';
import 'google_drive.dart';

class BackupManager {
  static Future<?> getSong(MusicData musicData) async {
    final backupLocation = musicData.backupLocation;
    if (backupLocation == null) return null;
    switch (backupLocation.service) {
      case "google_drive":
        return GoogleDriveBackupManager.getSong(musicData, backupLocation);
      default:
        throw ArgumentError("Invalid backup location.");
    }
  }
}


class BackupLocation {
  const BackupLocation(this.service, this.accountEmail);

  final String service;
  final String accountEmail;

  Map<String, dynamic> toJson() => {
    "service": service,
    "accountEmail": accountEmail,
  };

  factory BackupLocation.fromJson(Map<String, dynamic> json) {
    return BackupLocation(json["service"], json["accountEmail"]);
  }
}