import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/local_musics_data.dart';
import '../../data/playlist_data.dart';
import '../../data/settings_data.dart';
import '../../music/music_data/music_data.dart';
import '../../music/playlist/playlist.dart';
import '../../utils/map_utils.dart';

class CloudFirestoreManager {
  static Map<String, dynamic>? userData;

  static bool _isInitialized = false;

  /// Must run after initializing FirebaseAuth, LocalMusicsData, SettingsData,
  /// and PlaylistsData.
  static Future<void> init() async {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _onUserUpdate();
    }
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;
      _onUserUpdate();
    });
    _isInitialized = true;
  }

  static Future<void> _onUserUpdate() async {
    LocalMusicsData.localMusicData.resetData();
    SettingsData.settings.resetData();
    PlaylistsData.playlistsData.resetData();
    final tasks = <Future>[
      _listenUserDataUpdate(),
      _listenSongsUpdate(),
      _listenPlaylistsUpdate(),
    ];
    await Future.wait(tasks);
  }

  static Future<void> importData(Map<String, dynamic> data) async {
    await runTask(() async {
      if (data.containsKey("songs")) {
        LocalMusicsData.localMusicData.data = data["songs"];
        await LocalMusicsData.localMusicData
            .save(compact: LocalMusicsData.compact);
        await CloudFirestoreManager.removeAllSongs();
        await CloudFirestoreManager.addOrUpdateSongs(
            LocalMusicsData.getAllWithoutCaching());
      }
      if (data.containsKey("playlists")) {
        PlaylistsData.playlistsData.data = data["playlists"];
        await CloudFirestoreManager.removeAllPlaylists();
        await CloudFirestoreManager.addOrUpdatePlaylists(
            PlaylistsData.getAll());
      }
      if (data.containsKey("settings")) {
        SettingsData.settings.data = MapUtils.bindOptions(
            SettingsData.settings.defaultValue, data["settings"]);
        await SettingsData.save(upload: false);
        await SettingsData.applySettings();
      }
    });
  }

  static Map<String, dynamic> exportData(
      {required bool songs, required bool settings, required bool playlists}) {
    return {
      if (songs) "songs": LocalMusicsData.localMusicData.data,
      if (playlists) "playlists": PlaylistsData.playlistsData.data,
      if (settings) "settings": SettingsData.settings.data,
    };
  }

  // add or update songs
  static Future<void> addOrUpdateSongs(List<MusicData> songs) async {
    if (!_isInitialized) return;
    await runTask(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final collection = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("songs");
      final List<Future<void>> futures = [];
      for (final song in songs) {
        futures.add(collection.doc(song.audioId).set(song.toJson()));
      }
      await Future.wait(futures);
    });
  }

  static Future<void> removeSongs(List<String> audioIds) async {
    if (!_isInitialized) return;
    await runTask(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final collection = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("songs");
      final List<Future<void>> futures = [];
      for (final audioId in audioIds) {
        futures.add(collection.doc(audioId).delete());
      }
      await Future.wait(futures);
    });
  }

  static Future<void> removeAllSongs() async {
    if (!_isInitialized) return;
    await runTask(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final collection = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("songs");

      final songs = await collection.get();

      final List<Future<void>> futures = [];
      for (final docId in songs.docs.map((doc) => doc.id)) {
        futures.add(collection.doc(docId).delete());
      }
      await Future.wait(futures);
    });
  }

  // add or update playlists
  static Future<void> addOrUpdatePlaylists(List<AppPlaylist> playlists) async {
    if (!_isInitialized) return;
    await runTask(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final collection = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("playlists");
      final List<Future<void>> futures = [];
      for (final playlist in playlists) {
        futures.add(collection.doc(playlist.id).set(playlist.toJson()));
      }
      await Future.wait(futures);
    });
  }

  static Future<void> removePlaylists(List<String> playlistIds) async {
    if (!_isInitialized) return;
    await runTask(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final collection = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("playlists");
      final List<Future<void>> futures = [];
      for (final playlistId in playlistIds) {
        futures.add(collection.doc(playlistId).delete());
      }
      await Future.wait(futures);
    });
  }

  static Future<void> removeAllPlaylists() async {
    if (!_isInitialized) return;
    await runTask(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final collection = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("playlists");

      final playlists = await collection.get();

      final List<Future<void>> futures = [];
      for (final docId in playlists.docs.map((doc) => doc.id)) {
        futures.add(collection.doc(docId).delete());
      }
      await Future.wait(futures);
    });
  }

  static Future<void> updateUserData() async {
    if (!_isInitialized) return;
    await runTask(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final doc = FirebaseFirestore.instance.collection("users").doc(user.uid);

      final Map<String, dynamic> data = {
        "settings": SettingsData.settings.data
      };

      await doc.set(data);
    });
  }

  static StreamSubscription? _userDataStreamSubscription;
  static Future<void> _listenUserDataUpdate() async {
    if (_userDataStreamSubscription != null) {
      await _userDataStreamSubscription!.cancel();
    }
    await runTask(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final doc = FirebaseFirestore.instance.collection("users").doc(user.uid);

      final data = await doc.get();
      if (data.data() == null) {
        SettingsData.settings.resetData();
        await SettingsData.save(upload: false);
        await updateUserData();
      }

      _userDataStreamSubscription =
          doc.snapshots(includeMetadataChanges: true).listen((snapshot) {
        runTask(() async {
          final data = snapshot.data();
          print("database update (cache: ${snapshot.metadata.isFromCache})");
          if (data == null) return;
          SettingsData.settings.data = MapUtils.bindOptions(
              SettingsData.settings.defaultValue, data["settings"]);
          await SettingsData.save(upload: false);
          await SettingsData.applySettings();
        });
      });
    });
  }

  static StreamSubscription? _songsStreamSubscription;
  static Future<void> _listenSongsUpdate() async {
    if (_songsStreamSubscription != null) {
      await _songsStreamSubscription!.cancel();
    }
    await runTask(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final collection = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("songs");

      _songsStreamSubscription = collection.snapshots().listen((snapshot) {
        runTask(() async {
          final changes = snapshot.docChanges;
          if (changes.isEmpty) return;
          print(
              "[Asterfox Firestore] Added ${changes.where((change) => change.type == DocumentChangeType.added).length} songs. Modified ${changes.where((change) => change.type == DocumentChangeType.modified).length} songs. Removed ${changes.where((change) => change.type == DocumentChangeType.removed).length} songs.");
          for (final change in changes) {
            final audioId = change.doc.id;
            if (change.type == DocumentChangeType.removed) {
              LocalMusicsData.localMusicData.delete(key: audioId);
            } else {
              LocalMusicsData.localMusicData
                  .set(key: audioId, value: change.doc.data());
            }
          }
          await LocalMusicsData.localMusicData
              .save(compact: LocalMusicsData.compact);
        });
      });
    });
  }

  static StreamSubscription? _playlistsStreamSubscription;
  static Future<void> _listenPlaylistsUpdate() async {
    if (_playlistsStreamSubscription != null) {
      await _playlistsStreamSubscription!.cancel();
    }
    await runTask(() async {
      final user = FirebaseAuth.instance.currentUser!;
      final collection = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("playlists");

      _playlistsStreamSubscription = collection.snapshots().listen((snapshot) {
        runTask(() async {
          final changes = snapshot.docChanges;
          if (changes.isEmpty) return;
          print(
              "[Asterfox Firestore] Added ${changes.where((change) => change.type == DocumentChangeType.added).length} playlists. Modified ${changes.where((change) => change.type == DocumentChangeType.modified).length} playlists. Removed ${changes.where((change) => change.type == DocumentChangeType.removed).length} playlists.");
          for (final change in changes) {
            final playlistId = change.doc.id;
            if (change.type == DocumentChangeType.removed) {
              PlaylistsData.playlistsData.delete(key: playlistId);
            } else {
              PlaylistsData.playlistsData
                  .set(key: playlistId, value: change.doc.data());
            }
          }
          await PlaylistsData.playlistsData.save();
        });
      });
    });
  }

  static Future<void> cancelListeners() async {
    final List<Future> futures = [];
    if (_userDataStreamSubscription != null) {
      futures.add(_userDataStreamSubscription!.cancel());
    }
    if (_songsStreamSubscription != null) {
      futures.add(_songsStreamSubscription!.cancel());
    }
    if (_playlistsStreamSubscription != null) {
      futures.add(_playlistsStreamSubscription!.cancel());
    }

    await Future.wait(futures);
  }

  static ValueNotifier<int> runningTasks = ValueNotifier(0);
  static Future<T> runTask<T>(Future<T> Function() task) async {
    runningTasks.value = runningTasks.value + 1;
    final result = await task();
    runningTasks.value = runningTasks.value - 1;
    return result;
  }

  static Future<void> waitForTasks() async {
    if (runningTasks.value == 0) return;
    final completer = Completer();
    void listener() {
      if (runningTasks.value == 0) {
        completer.complete();
      }
    }

    runningTasks.addListener(listener);
    await completer.future;
    runningTasks.removeListener(listener);
  }
}
