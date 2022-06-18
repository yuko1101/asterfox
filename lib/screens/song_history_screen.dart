import 'package:asterfox/data/song_history_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/system/exceptions/network_exception.dart';
import 'package:asterfox/system/exceptions/refresh_url_failed_exception.dart';
import 'package:asterfox/system/home_screen_music_manager.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screen.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

class SongHistoryScreen extends BaseScreen {
  SongHistoryScreen() : super(
    appBar: const SongHistoryAppBar(),
    screen: const SongHistoryMainScreen(),
  );
}

class SongHistoryAppBar extends StatelessWidget with PreferredSizeWidget {
  const SongHistoryAppBar({
    Key? key,
  }) : super(key: key);
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(Language.getText("song_history")),
      leading: IconButton(
        onPressed: () => EasyApp.popPage(context),
        icon: const Icon(Icons.arrow_back),
        tooltip: Language.getText("go_back"),
      ),
    );
  }
}

class SongHistoryMainScreen extends StatefulWidget {
  const SongHistoryMainScreen({Key? key}) : super(key: key);

  @override
  State<SongHistoryMainScreen> createState() => _SongHistoryMainScreenState();
}

class _SongHistoryMainScreenState extends State<SongHistoryMainScreen> {
  @override
  Widget build(BuildContext context) {
    final songs = SongHistoryData.getAll(isTemporary: true).reversed.toList();
    return SafeArea(
        child: songs.isEmpty ? Center(
          child: Text(Language.getText("no_song_history"), style: TextStyle(color: Theme.of(context).extraColors.secondary)),
        ) : ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              title: Text(song.title),
              subtitle: Text(song.author),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: Language.getText("delete_from_history"),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(Language.getText("delete_from_history")),
                      content: Text(Language.getText("delete_from_history_confirm_message")),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(Language.getText("cancel")),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              SongHistoryData.removeFromHistory(song);
                              Navigator.pop(context);
                            });
                          },
                          child: Text(Language.getText("delete")),
                        ),
                      ],
                    ),

                  );

                },
              ),
              onTap: () async {
                final key = const Uuid().v4();
                try {
                  final musicData = await song.renew(key);
                  HomeScreenMusicManager.addSong(key: key, musicData: musicData);
                  EasyApp.popPage(context);
                } on RefreshUrlFailedException {
                  // TODO: multi-language
                  Fluttertoast.showToast(msg: "Failed to refresh url");
                } on NetworkException {
                  Fluttertoast.showToast(msg: Language.getText("network_not_accessible"));
                }
              },
            );
          },
        ),
    );
  }
}
