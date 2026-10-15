import 'package:asterfox/main.dart';
import 'package:asterfox/music/manager/song_preview.dart';
import 'package:asterfox/music/music_data/music_data.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_preview.dart';

/// A song whose audio is where it already is, so that hearing it needs no
/// network and no device.
MusicData<CachingDisabled> song(String audioId) => MusicData<CachingDisabled>(
      type: MusicType.youtube,
      remoteAudioUrl: "https://example.com/$audioId",
      remoteImageUrl: "https://example.com/$audioId.png",
      title: audioId,
      description: "",
      author: "Author",
      keywords: const [],
      audioId: audioId,
      duration: const Duration(seconds: 100),
      volume: 1,
      lyrics: "",
      songStoredAt: 1,
      size: null,
      caching: CachingDisabled(),
    );

void main() {
  // `localPath` is `late final` in main.dart, so it can only be written once
  // for the whole run. Nothing in this file is on disk.
  setUpAll(() => localPath = '/nonexistent');

  test('a preview plays the song on a player of its own', () async {
    final player = FakePreviewPlayer();
    final preview = SongPreview(createPlayer: () => player);

    await preview.start(song("a"), videoId: "a");

    expect(player.opened, ["https://example.com/a"]);
    expect(preview.song?.audioId, "a");
  });

  test('the queue stands aside for a preview and is taken up again', () async {
    final player = FakePreviewPlayer();
    final queue = FakeQueue(playing: true);
    final preview = SongPreview(createPlayer: () => player, queue: queue);

    await preview.start(song("a"), videoId: "a");

    expect(queue.calls, ["pause"], reason: "the queue is stood aside for");
    expect(player.opened, ["https://example.com/a"]);

    await preview.stop();

    expect(queue.calls, ["pause", "resume"], reason: "and taken up again");
    expect(preview.song, isNull);
  });

  test('a queue that was paused is left paused', () async {
    // A preview does not start music that nobody asked for.
    final player = FakePreviewPlayer();
    final queue = FakeQueue(playing: false);
    final preview = SongPreview(createPlayer: () => player, queue: queue);

    await preview.start(song("a"), videoId: "a");
    await preview.stop();

    expect(queue.calls, isEmpty);
  });

  test('the queue is stood aside for once, however many songs are heard',
      () async {
    // The second preview starts where the first one left the queue, rather than
    // pausing a queue that is already paused.
    final player = FakePreviewPlayer();
    final queue = FakeQueue(playing: true);
    final preview = SongPreview(createPlayer: () => player, queue: queue);

    await preview.start(song("a"), videoId: "a");
    await preview.start(song("b"), videoId: "b");

    expect(queue.calls, ["pause"]);
    expect(preview.song?.audioId, "b");
    expect(player.opened, [
      "https://example.com/a",
      "https://example.com/b",
    ]);

    await preview.stop();
    expect(queue.calls, ["pause", "resume"]);
  });

  test('stopping a preview that is not on leaves the queue alone', () async {
    final player = FakePreviewPlayer();
    final queue = FakeQueue(playing: true);
    final preview = SongPreview(createPlayer: () => player, queue: queue);

    await preview.stop();

    expect(queue.calls, isEmpty);
    expect(player.opened, isEmpty);
  });

  test('the player is made when the first song is heard', () async {
    // The screen that offers a preview can be opened without a player being
    // made for it, since a player of this app is libmpv.
    final player = FakePreviewPlayer();
    var made = 0;
    final preview = SongPreview(createPlayer: () {
      made++;
      return player;
    });

    expect(made, 0);
    await preview.start(song("a"), videoId: "a");
    expect(made, 1);
    await preview.stop();
    await preview.start(song("b"), videoId: "b");
    expect(made, 1, reason: "one player serves every preview");
  });

  test('disposing ends the preview and lets the player go', () async {
    final player = FakePreviewPlayer();
    final queue = FakeQueue(playing: true);
    final preview = SongPreview(createPlayer: () => player, queue: queue);

    await preview.start(song("a"), videoId: "a");
    await preview.dispose();

    expect(player.stops, 1);
    expect(player.disposes, 1);
    expect(queue.calls, ["pause", "resume"]);
  });

  test('the volume of a preview follows the volume of the queue', () async {
    final player = FakePreviewPlayer();
    final queue = FakeQueue(volume: 0.25);
    final preview = SongPreview(createPlayer: () => player, queue: queue);

    await preview.start(song("a"), videoId: "a");

    expect(player.lastVolume, 0.25);
  });

  test('pausing and playing a preview does not touch the queue', () async {
    final player = FakePreviewPlayer();
    final queue = FakeQueue(playing: true);
    final preview = SongPreview(createPlayer: () => player, queue: queue);

    await preview.start(song("a"), videoId: "a");
    await preview.togglePlay();
    await preview.togglePlay();

    expect(queue.calls, ["pause"]);
    expect(player.pauses, 1);
    expect(player.plays, 1);
  });

  test('the preview says whether it is playing', () async {
    // The bar is drawn from this, so it has to follow the player rather than
    // the button that was pressed.
    final player = FakePreviewPlayer();
    final preview = SongPreview(createPlayer: () => player);

    final seen = <bool>[];
    preview.playing.addListener(() => seen.add(preview.playing.value));

    await preview.start(song("a"), videoId: "a");
    await player.pause();
    await expectLater(Future<void>.delayed(Duration.zero), completes);

    expect(seen, [true, false]);
  });

  test('the progress of the preview follows the player', () async {
    final player = FakePreviewPlayer();
    final preview = SongPreview(createPlayer: () => player);

    await preview.start(song("a"), videoId: "a");
    player.emitDuration(const Duration(seconds: 100));
    player.emitBuffer(const Duration(seconds: 10));
    player.emitPosition(const Duration(seconds: 5));
    await expectLater(Future<void>.delayed(Duration.zero), completes);

    expect(preview.progress.value.duration, const Duration(seconds: 100));
    expect(preview.progress.value.buffer, const Duration(seconds: 10));
    expect(preview.progress.value.position, const Duration(seconds: 5));
  });

  test('an audio that arrives after the preview ended is dropped', () async {
    // Leaving the screen while the audio is on its way must not start playing
    // a song on a screen that is gone.
    final player = FakePreviewPlayer();
    final queue = FakeQueue(playing: true);
    final preview = SongPreview(createPlayer: () => player, queue: queue);

    final pending = preview.start(song("a"), videoId: "a");
    await preview.stop();
    await preview.dispose();
    await pending;

    expect(player.opened, isEmpty);
    expect(queue.calls, isEmpty);
  });

  test('seeking a preview that is not on does nothing', () async {
    final player = FakePreviewPlayer();
    final preview = SongPreview(createPlayer: () => player);

    await preview.seek(const Duration(seconds: 30));

    expect(player.lastSeek, isNull);
  });
}
