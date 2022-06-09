import 'package:asterfox/data/song_history_data.dart';
import 'package:asterfox/main.dart';
import 'package:asterfox/music/audio_source/music_data.dart';
import 'package:asterfox/system/theme/theme.dart';
import 'package:easy_app/easy_app.dart';
import 'package:easy_app/screen/base_screen.dart';
import 'package:easy_app/utils/languages.dart';
import 'package:flutter/material.dart';

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
    final songs = SongHistoryData.getAll();
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
                onPressed: () {
                  setState(() {
                    SongHistoryData.removeFromHistory(song);
                  });
                },
              ),
              onTap: () {
                  musicManager.add(song);
                  EasyApp.popPage(context);
              },
            );
          },
        ),
    );
  }
}
