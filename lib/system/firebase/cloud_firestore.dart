import 'dart:async';

import 'package:asterfox/data/local_musics_data.dart';
import 'package:asterfox/data/settings_data.dart';
import 'package:asterfox/utils/map_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudFirestoreManager {
  static Map<String, dynamic>? userData;

  static bool _isInitialized = false;

  /// Must run after initializing FirebaseAuth, LocalMusicsData, SettingsData,
  /// and TemporaryData.
  static Future<void> init() async {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _listenDataUpdate();
    }
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;
      _listenDataUpdate();
    });
    _isInitialized = true;
  }

  static Future<void> update() async {
    if (!_isInitialized) return;
    final user = FirebaseAuth.instance.currentUser!;
    final Map<String, dynamic> data = {
      "songs": LocalMusicsData.musicData.data,
      "settings": SettingsData.settings.data,
    };
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set(data);
  }

  static StreamSubscription? _streamSubscription;
  static Future<void> _listenDataUpdate() async {
    if (_streamSubscription != null) await _streamSubscription!.cancel();
    final user = FirebaseAuth.instance.currentUser!;
    final doc = FirebaseFirestore.instance.collection("users").doc(user.uid);

    final data = await doc.get();
    if (data.data() == null) {
      LocalMusicsData.musicData.resetData();
      SettingsData.settings.resetData();
      await Future.wait([LocalMusicsData.saveData(), SettingsData.save()]);
      await update();
    }

    _streamSubscription = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) async {
      final data = snapshot.data();
      print("database update (cache: ${snapshot.metadata.isFromCache})");
      if (data == null) return;
      LocalMusicsData.musicData.data = data["songs"];
      SettingsData.settings.data = MapUtils.bindOptions(
          SettingsData.settings.defaultValue, data["settings"]);
      await Future.wait([
        LocalMusicsData.saveData(upload: false),
        SettingsData.save(upload: false),
      ]);
      await Future.wait([
        SettingsData.applySettings(),
      ]);
    });
  }
}
