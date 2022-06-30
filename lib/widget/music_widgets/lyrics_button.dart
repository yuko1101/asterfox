import 'package:flutter/material.dart';

class LyricsButton extends StatelessWidget {
  const LyricsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.lyrics_outlined,
        shadows: [
          BoxShadow(
            color: Theme.of(context).backgroundColor,
            offset: const Offset(0, 0),
            blurRadius: 10,
          ),
        ],
      ),
      onPressed: () {
        // TODO: display lyrics
      },
    );
  }
}
