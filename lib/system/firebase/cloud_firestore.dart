import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/database.dart';
import '../../data/local_musics_data.dart';
import '../../data/playlist_data.dart';
import '../../data/settings_data.dart';
import '../../data/song_history_data.dart';
import '../../music/music_data/music_data.dart';
import '../../music/playlist/playlist.dart';
import '../../utils/map_utils.dart';

class CloudFirestoreManager {
  static bool _isInitialized = false;

  /// Must run after initializing FirebaseAuth, LocalMusicsData, SettingsData,
  /// and PlaylistsData.
  static Future<void> init() async {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    // The stream starts with the current user, so a signed in user is handled
    // here too, once.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _onUserUpdate();
    });
    _isInitialized = true;
  }

  static Future<void> _onUserUpdate() async {
    AppDatabase.currentUser = FirebaseAuth.instance.currentUser?.uid;
    await LocalMusicsData.reloadDatabase();
    await SettingsData.reloadDatabase();
    await PlaylistsData.reloadDatabase();
    await SongHistoryData.reloadDatabase();
    await Future.wait([
      _listenUserDataUpdate(),
      _listenSongsUpdate(),
      _listenPlaylistsUpdate(),
    ]);
  }

  /// The document of the signed in user, or null when the cloud is not used
  /// right now (not initialized, or nobody is signed in).
  static DocumentReference<Map<String, dynamic>>? get _userDoc {
    if (!_isInitialized) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection("users").doc(user.uid);
  }

  static Future<void> importData(Map<String, dynamic> data) async {
    await runTask(() async {
      if (data.containsKey("songs")) {
        await LocalMusicsData.replaceAll(
            Map<String, dynamic>.from(data["songs"] as Map));
        await removeAllSongs();
        await addOrUpdateSongs(
            LocalMusicsData.getAll(caching: CachingDisabled()));
      }
      if (data.containsKey("playlists")) {
        await PlaylistsData.replaceAll(
            Map<String, dynamic>.from(data["playlists"] as Map));
        await removeAllPlaylists();
        await addOrUpdatePlaylists(PlaylistsData.getAll());
      }
      if (data.containsKey("settings")) {
        await SettingsData.applyRemoteData(
            MapUtils.bindOptions(SettingsData.defaultData, data["settings"]));
        await SettingsData.applySettings();
      }
    });
  }

  static Map<String, dynamic> exportData(
      {required bool songs, required bool settings, required bool playlists}) {
    return {
      if (songs) "songs": LocalMusicsData.getStoredData(),
      if (playlists) "playlists": PlaylistsData.getStoredData(),
      if (settings) "settings": SettingsData.data,
    };
  }

  /// Writes [docs] (id to data) to [collection] of the user, and deletes the
  /// ids mapped to null.
  static Future<void> _write(
      String collection, Map<String, Map<String, dynamic>?> docs) async {
    final userDoc = _userDoc;
    if (userDoc == null || docs.isEmpty) return;
    await runTask(() async {
      final ref = userDoc.collection(collection);
      await Future.wait([
        for (final MapEntry(key: id, value: data) in docs.entries)
          data == null ? ref.doc(id).delete() : ref.doc(id).set(data),
      ]);
    });
  }

  static Future<void> _removeAll(String collection) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await runTask(() async {
      final docs = await userDoc.collection(collection).get();
      await Future.wait(docs.docs.map((doc) => doc.reference.delete()));
    });
  }

  static Future<void> addOrUpdateSongs(List<MusicData> songs) =>
      _write("songs", {for (final song in songs) song.audioId: song.toJson()});

  static Future<void> removeSongs(List<String> audioIds) =>
      _write("songs", {for (final id in audioIds) id: null});

  static Future<void> removeAllSongs() => _removeAll("songs");

  static Future<void> addOrUpdatePlaylists(List<AppPlaylist> playlists) =>
      _write("playlists", {
        for (final playlist in playlists) playlist.id: playlist.toJson(),
      });

  static Future<void> removePlaylists(List<String> playlistIds) =>
      _write("playlists", {for (final id in playlistIds) id: null});

  static Future<void> removeAllPlaylists() => _removeAll("playlists");

  static Future<void> updateUserData() async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await runTask(() => userDoc.set({"settings": SettingsData.data}));
  }

  static StreamSubscription? _userDataStreamSubscription;
  static Future<void> _listenUserDataUpdate() async {
    await _userDataStreamSubscription?.cancel();
    _userDataStreamSubscription = null;
    final userDoc = _userDoc;
    if (userDoc == null) return;

    await runTask(() async {
      final data = await userDoc.get();
      if (data.data() == null) {
        await SettingsData.resetData();
        await updateUserData();
      }

      _userDataStreamSubscription =
          userDoc.snapshots(includeMetadataChanges: true).listen((snapshot) {
        runTask(() async {
          final data = snapshot.data();
          if (data == null) return;
          await SettingsData.applyRemoteData(
              MapUtils.bindOptions(SettingsData.defaultData, data["settings"]));
          await SettingsData.applySettings();
        });
      });
    });
  }

  static StreamSubscription? _songsStreamSubscription;
  static Future<void> _listenSongsUpdate() async {
    await _songsStreamSubscription?.cancel();
    _songsStreamSubscription = _listenCollection(
      "songs",
      (id, json) => LocalMusicsData.applyRemoteChange(audioId: id, json: json),
    );
  }

  static StreamSubscription? _playlistsStreamSubscription;
  static Future<void> _listenPlaylistsUpdate() async {
    await _playlistsStreamSubscription?.cancel();
    _playlistsStreamSubscription = _listenCollection(
      "playlists",
      (id, json) => PlaylistsData.applyRemoteChange(playlistId: id, json: json),
    );
  }

  /// Applies the changes of [collection] of the user as they come. A removed
  /// document is applied as null.
  static StreamSubscription? _listenCollection(
    String collection,
    Future<void> Function(String id, Map<String, dynamic>? json) apply,
  ) {
    final userDoc = _userDoc;
    if (userDoc == null) return null;
    return userDoc.collection(collection).snapshots().listen((snapshot) {
      final changes = snapshot.docChanges;
      if (changes.isEmpty) return;
      runTask(() async {
        for (final change in changes) {
          await apply(
            change.doc.id,
            change.type == DocumentChangeType.removed
                ? null
                : Map<String, dynamic>.from(change.doc.data()!),
          );
        }
      });
    });
  }

  static Future<void> cancelListeners() async {
    await Future.wait([
      if (_userDataStreamSubscription != null)
        _userDataStreamSubscription!.cancel(),
      if (_songsStreamSubscription != null) _songsStreamSubscription!.cancel(),
      if (_playlistsStreamSubscription != null)
        _playlistsStreamSubscription!.cancel(),
    ]);
    _userDataStreamSubscription = null;
    _songsStreamSubscription = null;
    _playlistsStreamSubscription = null;
  }

  static ValueNotifier<int> runningTasks = ValueNotifier(0);

  /// Runs [task], counted in [runningTasks] until it has finished or failed.
  static Future<T> runTask<T>(Future<T> Function() task) async {
    runningTasks.value++;
    try {
      return await task();
    } finally {
      runningTasks.value--;
    }
  }

  static Future<void> waitForTasks() async {
    if (runningTasks.value == 0) return;
    final completer = Completer<void>();
    void listener() {
      if (runningTasks.value == 0 && !completer.isCompleted) {
        completer.complete();
      }
    }

    runningTasks.addListener(listener);
    await completer.future;
    runningTasks.removeListener(listener);
  }
}
