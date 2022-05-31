import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/music/audio_source/youtube_music_data.dart';
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
        final MusicData song =
          musicManager.audioDataManager.currentSong!;
        Share.share(song.mediaURL, subject: song.title);
        Navigator.pop(context);
      },
      songFilter: (MusicData? song) => song != null,
    ),
    _Action(
        id: "youtube",
        icon: Icons.open_in_new,
        title: Language.getText("open_in_youtube"),
        onTap: (context) async {
          final launched = await launchUrl(Uri.parse(musicManager.audioDataManager.currentSong!.mediaURL), mode: LaunchMode.externalNonBrowserApplication);
          if (!launched) {
            Fluttertoast.showToast(msg: Language.getText("launch_url_error"));
          }
          Navigator.pop(context);
        },
        songFilter: (MusicData? song) => song != null && song is YouTubeMusicData,
    ),
    _Action(
      id: "export",
      icon: Icons.file_download,
      title: Language.getText("export_as_mp3"),
      onTap: (context) {
        Navigator.pop(context);
      },
      songFilter: (MusicData? song) => song != null,
    ),
    _Action(
        id: "refresh_all",
        icon: Icons.refresh,
        title: Language.getText("refresh_all"),
        onTap: (context) {
          musicManager.refreshSongs();
          Navigator.pop(context);
        },
        songFilter: (MusicData? song) => song != null,
    )
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MusicData?>(
        valueListenable: musicManager.currentSongNotifier,
        builder: (context, song, child) {
          return IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _actions.indexWhere((action) => action.songFilter(song)) == -1 ? null : () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  enableDrag: true,
                  builder: (context) => Container(
                    margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                    child: Material(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      // 一番下のListTileの角が丸まらないのを直す
                      clipBehavior: Clip.antiAlias,
                      color: Theme.of(context).backgroundColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
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
                          SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              children: _actions.where((action) => action.songFilter(song)).toList(),

                            ),
                          )
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
  final bool Function(MusicData?) songFilter;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      autofocus: true,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: () => onTap(context),
        tileColor: Theme.of(context).backgroundColor,
      ),
    );
  }
}
