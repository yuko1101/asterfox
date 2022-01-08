import 'package:audio_service/audio_service.dart';

import 'music_detail.dart';
import 'package:uuid/uuid.dart';


class MusicData {
  MusicData({
    required this.url,
    required this.detail,
    required this.audioType,
  });
  final String url;
  final MusicDetail detail;
  final AudioType audioType;

  final String uuid = const Uuid().v4();

  MediaItem getMediaItem() {
    return MediaItem(
        id: uuid,
        title: detail.title,
        extras: {
          "tag": toRawJson(),
          "url": url
        }
    );
  }


  Map<String, dynamic> toRawJson() {
    return {
      "url": url,
      "detail": detail.toJson(),
      "audioType": audioTypeMap.entries.firstWhere((element) => element.value == audioType).key
    };
  }

  MusicData.fromRawJson(Map<String, dynamic> json)
    : url = json["url"],
      detail = MusicDetail.fromJson(json["detail"]),
      audioType = audioTypeMap[json["audioType"]]!;

  Map<String, dynamic> toJson() {
    return detail.toJson();
  }

  MusicData.fromJson(Map<String, dynamic> json)
    : url = "",
      detail = MusicDetail.fromJson(json),
      audioType = AudioType.local;


  @override
  String toString() {
    // TODO: implement toString
    return "MusicData(url=\"$url\",detail=$detail,audioType=$audioType)";
  }

}

enum AudioType {
  local,
  remote
}

Map<String, AudioType> audioTypeMap = {
  "local": AudioType.local,
  "remote": AudioType.remote
};


extension ParseMusicData on MediaItem {
  MusicData asMusicData() {
    return MusicData.fromRawJson(extras!["tag"]);
  }
}