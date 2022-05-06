import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/base/audio_base.dart';
import 'package:asterfox/music/audio_source/base/media_audio.dart';
import 'package:asterfox/music/audio_source/youtube_audio.dart';
import 'package:asterfox/system/languages.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MoreActionsButton extends StatelessWidget {
  const MoreActionsButton({
    Key? key,
  }) : super(key: key);

  // TODO: Add more actions
  static final List<_Action> _actions = [
    _Action(
      id: "share",
      icon: Icons.share,
      title: Language.getText("share"),
      onTap: (context) async {
        final MediaAudio song =
            musicManager.currentSongNotifier.value as MediaAudio;
        Share.share(song.getMediaURL(), subject: song.title);
        Navigator.pop(context);
      },
      songFilter: (AudioBase? song) => song != null && song is MediaAudio,
    ),
    _Action(
        id: "youtube",
        icon: Icons.open_in_new,
        title: Language.getText("open_in_youtube"),
        onTap: (context) async {
          final launched = await launchUrl(Uri.parse((musicManager.currentSongNotifier.value as MediaAudio).getMediaURL()), mode: LaunchMode.externalNonBrowserApplication);
          if (!launched) {
            Fluttertoast.showToast(msg: Language.getText("launch_url_error"));
          }
          Navigator.pop(context);
        },
        songFilter: (AudioBase? song) => song != null && song is YouTubeAudio,
    ),
    _Action(
      id: "export",
      icon: Icons.file_download,
      title: Language.getText("export_as_mp3"),
      onTap: (context) {
        Navigator.pop(context);
      },
      songFilter: (AudioBase? song) => song != null,
    ),
    _Action(
        id: "refresh_all",
        icon: Icons.refresh,
        title: Language.getText("refresh_all"),
        onTap: (context) {
          musicManager.refreshSongs();
          Navigator.pop(context);
        },
        songFilter: (AudioBase? song) => song != null,
    )
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioBase?>(
        valueListenable: musicManager.currentSongNotifier,
        builder: (context, song, child) {
          return IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _actions.indexWhere((action) => action.songFilter(song)) == -1 ? null : () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  enableDrag: true,
                  builder: (context) => SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          color: Theme.of(context).backgroundColor),
                      margin: const EdgeInsets.only(left: 10, right: 10),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                              color: Theme.of(context).textTheme.headline1?.color?.withOpacity(0.1),
                            ),
                            margin: const EdgeInsets.only(top: 7, bottom: 4),
                            height: 5,
                            width: 40,
                          ),
                          ..._actions.where((action) => action.songFilter(song))
                        ],
                      ),
                    ),
                  ),
                );
              });
        });
  }
}

class _Action extends StatelessWidget {
  const _Action({
    Key? key,
    required this.id,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.songFilter,
  }) : super(key: key);

  final String id;
  final IconData icon;
  final String title;
  final void Function(BuildContext) onTap;
  final bool Function(AudioBase?) songFilter;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => onTap(context)
    );
  }
}
