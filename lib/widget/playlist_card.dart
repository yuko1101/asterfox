import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/local_musics_data.dart';
import '../music/audio_source/music_data.dart';
import '../music/playlist/playlist.dart';
import '../music/utils/music_data_utils.dart';
import '../utils/network_utils.dart';
import 'music_widgets/music_thumbnail.dart';

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({required this.playlist, this.onTap, this.onLongPress, super.key});

  final AppPlaylist playlist;
  final void Function()? onTap;
  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          playlist.songs.isEmpty
              // TODO: better empty widget
              ? const Text("Empty")
              : FourImagesGrid(
                  playlist.songs
                      .take(4)
                      .map((audioId) => LocalMusicsData.getByAudioId(
                          audioId: audioId,
                          key: const Uuid().v4(),
                          caching: CachingDisabled()))
                      .map((song) {
                    final image = song.imageUrl;
                    if (image.isUrl) {
                      if (!NetworkUtils.networkAccessible()) {
                        return getDefaultImage(BoxFit.cover);
                      }
                      return Image.network(
                        image,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                      );
                    }
                    return Image.file(
                      File(image),
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                    );
                  }).toList(),
                ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 30,
              width: double.infinity,
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
              child: Text(
                playlist.name,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
        ],
      ),
    );
  }
}

class FourImagesGrid extends StatelessWidget {
  FourImagesGrid(this.images, {super.key}) {
    if (images.length > 4) {
      throw Exception("FourImagesGrid cannot have more than 4 images");
    } else if (images.isEmpty) {
      throw Exception("FourImagesGrid must have at least 1 image");
    }
  }

  final List<Widget> images;

  @override
  Widget build(BuildContext context) {
    switch (images.length) {
      case 1:
        return images[0];
      case 2:
        return Column(
          children: images.map((img) => Expanded(child: img)).toList(),
        );
      case 3:
        return Column(
          children: [
            Expanded(child: images[0]),
            Expanded(
              child: Row(
                children: images
                    .sublist(1)
                    .map((img) => Expanded(child: img))
                    .toList(),
              ),
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: images
                    .sublist(0, 2)
                    .map((img) => Expanded(child: img))
                    .toList(),
              ),
            ),
            Expanded(
              child: Row(
                children: images
                    .sublist(2)
                    .map((img) => Expanded(child: img))
                    .toList(),
              ),
            ),
          ],
        );
      default:
        throw Exception(
            "FourImagesGrid must have at least 1 image and at most 4 images");
    }
  }
}
