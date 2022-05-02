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
      songFilter: (AudioBase? song) => song != null && song is MediaAudio,
      onTap: () async {
        final MediaAudio song =
            musicManager.currentSongNotifier.value as MediaAudio;
        Share.share(song.getMediaURL(), subject: song.title);
      }
    ),
    _Action(
        id: "youtube",
        icon: Icons.open_in_new,
        title: Language.getText("open_in_youtube"),
        songFilter: (AudioBase? song) => song != null && song is YouTubeAudio,
        onTap: () async {
          final launched = await launchUrl(Uri.parse((musicManager.currentSongNotifier.value as MediaAudio).getMediaURL()));
          if (!launched) {
            Fluttertoast.showToast(msg: Language.getText("launch_url_error"));
          }
        }
    ),
    _Action(
      id: "export",
      icon: Icons.file_download,
      title: Language.getText("export_as_mp3"),
      songFilter: (AudioBase? song) => song != null,
      onTap: () {}
    ),
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
  final VoidCallback onTap;
  final bool Function(AudioBase?) songFilter;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
