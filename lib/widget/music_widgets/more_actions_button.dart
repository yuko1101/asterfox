import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/local_musics_data.dart';
import '../../main.dart';
import '../../music/downloader/audio_downloader.dart';
import '../../music/manager/audio_data_manager.dart';
import '../../music/music_data/music_data.dart';
import '../../music/music_data/youtube_music_data.dart';
import '../../music/downloader/downloader_manager.dart';
import '../../system/theme/theme.dart';
import '../loading_dialog.dart';

class MoreActionsButton extends StatelessWidget {
  const MoreActionsButton({
    super.key,
  });

  // TODO: Add more actions
  static final List<_Action> _actions = [
    _Action(
      id: "share",
      icon: Icons.share,
      title: (context) => l10n.value.share,
      onTap: (song, context) async {
        Share.share(song!.mediaURL, subject: song.title);
        Navigator.of(context).pop();
      },
      songFilter: (MusicData? song) => song != null,
    ),
    _Action(
      id: "share_mp3",
      icon: Icons.share,
      title: (context) => l10n.value.share_mp3,
      onTap: (song, context) async {
        Navigator.of(context).pop();
        if (!song!.isInstalled) {
          final key = "share-${song.key}";
          final downloadPath = File("$tempPath/share_files/${song.key}");
          final downloadFuture = AudioDownloader.download(song, customPath: downloadPath.path);

          await LoadingDialog.showLoading(
            context: context,
            future: () async {
              await downloadFuture;
            }(),
            percentageNotifier: DownloadManager.getNotifiers(key).second,
          );
          // TODO: rename file
          await Share.shareXFiles([XFile(downloadPath.path)]);
        } else {
          await Share.shareXFiles([XFile(song.audioSavePath)]);
        }
      },
      songFilter: (MusicData? song) => song != null,
    ),
    _Action(
      id: "youtube",
      icon: Icons.open_in_new,
      title: (context) => l10n.value.open_in_youtube,
      onTap: (song, context) async {
        final launched = await launchUrl(Uri.parse(song!.mediaURL),
            mode: LaunchMode.externalNonBrowserApplication);
        if (!launched) {
          Fluttertoast.showToast(msg: l10n.value.launch_url_error);
        }
        Navigator.of(context).pop();
      },
      songFilter: (MusicData? song) => song != null && song is YouTubeMusicData,
    ),
    _Action(
      id: "export",
      icon: Icons.file_download,
      title: (context) => l10n.value.export_as_mp3,
      onTap: (song, context) {
        Navigator.of(context).pop();
      },
      songFilter: (MusicData? song) => song != null,
    ),
    _Action(
      id: "delete_from_local",
      icon: Icons.delete_forever,
      title: (context) => l10n.value.delete_from_local,
      onTap: (song, context) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.value.delete_from_local),
            content: Text(l10n.value.delete_from_local_confirm_message),
            actions: [
              TextButton(
                child: Text(l10n.value.cancel),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(l10n.value.delete),
                onPressed: () {
                  Navigator.of(context).pop();
                  song!.delete();
                },
              ),
            ],
          ),
        );
      },
      songFilter: (MusicData? song) => song != null && song.isStored,
    ),
    _Action(
      id: "refresh_all",
      icon: Icons.refresh,
      title: (context) => l10n.value.refresh_all,
      onTap: (song, context) {
        musicManager.refreshSongs();
        Navigator.of(context).pop();
      },
      songFilter: (MusicData? song) => song != null,
    )
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: musicManager.audioStateManager.currentSongNotifier,
      builder: (context, state, child) {
        final song = state.currentSong;
        return IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: l10n.value.more_actions,
          onPressed: _actions.any((action) => action.songFilter(song))
              ? () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    enableDrag: true,
                    elevation: 0,
                    builder: (context) => Container(
                      margin: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                        bottom: 10,
                      ),
                      child: Material(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        // 一番下のListTileの角が丸まらないのを直す
                        clipBehavior: Clip.antiAlias,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(20),
                                ),
                                color: Theme.of(context)
                                    .extraColors
                                    .primary
                                    .withOpacity(0.1),
                              ),
                              margin: const EdgeInsets.only(
                                top: 7,
                                bottom: 4,
                              ),
                              height: 5,
                              width: 40,
                            ),
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: _actions
                                      .where(
                                          (action) => action.songFilter(song))
                                      .toList(),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.id,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.songFilter,
  });

  final String id;
  final IconData icon;
  final String Function(BuildContext) title;
  final void Function(MusicData?, BuildContext) onTap;
  final bool Function(MusicData?) songFilter;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      autofocus: true,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title(context)),
        onTap: () => onTap(musicManager.state.currentSong, context),
        tileColor: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}
