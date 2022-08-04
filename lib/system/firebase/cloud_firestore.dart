import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/data/settings_data.dart';
import 'package:asterfox/system/exceptions/not_logged_in_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudFirestoreManager {
  static Map<String, dynamic>? userData;

  /// Must run after initializing FirebaseAuth, LocalMusicsData, and SettingsData
  static Future<void> init() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await getUserData();
    }
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      await getUserData(user);
    });
  }

  /// Throws [NotLoggedInException] if Firebase's currentUser is null
  static Future<Map<String, dynamic>?> getUserData([User? user]) async {
    final User? target = user ?? FirebaseAuth.instance.currentUser;
    if (target == null) throw NotLoggedInException();

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

  /// Throws [NotLoggedInException] if Firebase's currentUser is null
  static Future<void> setUserData(Map<String, dynamic> data) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw NotLoggedInException();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set(data);
    userData = data;
  }
}
