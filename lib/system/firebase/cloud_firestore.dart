import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/data/settings_data.dart';
import 'package:asterfox/data/temporary_data.dart';
import 'package:asterfox/system/exceptions/not_logged_in_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudFirestoreManager {
  static Map<String, dynamic>? userData;

  /// Must run after initializing FirebaseAuth, LocalMusicsData, SettingsData,
  /// and TemporaryData.
  static Future<void> init() async {
    if (FirebaseAuth.instance.currentUser != null) {
      if (!TemporaryData.getValue(key: "offline_changes")) {
        await applyToLocal();
      } else {
        await upload();
        TemporaryData.data.set(key: "offline_changes", value: false);
        await TemporaryData.save();
      }
    }
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      await applyToLocal(user);
    });
  }

  /// Returns null if Firebase's currentUser is null.
  static Future<Map<String, dynamic>?> getUserData([User? user]) async {
    final User? target = user ?? FirebaseAuth.instance.currentUser;
    if (target == null) {
      userData = null;
      return null;
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(target.uid)
        .get();
    final data = doc.data();

    if (data == null) {
      await setUserData({
        "settings": SettingsData.settings.data,
        "songs": LocalMusicsData.musicData.data
      });
    } else {
      userData = data;
    }
    return data;
  }

  /// Throws [NotLoggedInException] if Firebase's currentUser is null.
  static Future<void> setUserData(Map<String, dynamic> data) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw NotLoggedInException();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set(data);
    userData = data;
  }

  static Future<void> applyToLocal([User? user]) async {
    print("apply to local");
    final data = await getUserData(user);
    if (data == null) return;

    LocalMusicsData.musicData.data = data["songs"];
    SettingsData.settings.data = data["settings"];

    print(data["settings"]);
    print(SettingsData.settings.data);

    await Future.wait([
      LocalMusicsData.musicData.save(),
      SettingsData.settings.save(),
      SettingsData.applySettings(),
      SettingsData.applyMusicManagerSettings(),
    ]);
  }

  /// Throws [NotLoggedInException] if Firebase's currentUser is null.
  static Future<void> upload() async {
    await setUserData({
      "settings": SettingsData.settings.data,
      "songs": LocalMusicsData.musicData.data
    });
  }
}
