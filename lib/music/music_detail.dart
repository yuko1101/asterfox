class MusicDetail {
  MusicDetail({
    required this.videoId,
    required this.title,
    required this.description,
    required this.author,
    required this.authorId,
    required this.playedCount,
    required this.timestamp
  });
  final String videoId;
  final String title;
  final String description;
  final String author;
  final String authorId;
  final int playedCount;

  final int timestamp;

  Map<String, dynamic> toJson() {
    return {
      "videoId": videoId,
      "title": title,
      "description": description,
      "author": author,
      "authorId": authorId,
      "playedCount": playedCount,
      "timestamp": timestamp
    };
  }

  MusicDetail.fromJson(Map<String, dynamic> json)
      : videoId = json["videoId"],
        title = json["title"],
        description = json["description"],
        author = json["author"],
        authorId = json["authorId"],
        playedCount = json["playedCount"],
        timestamp = json["timestamp"];


  @override
  String toString() {
    return "MusicDetail(videoId=$videoId,title=$title,description=$description,author=$author,authorId=$authorId,playedCount=$playedCount,timestamp=$timestamp)";
  }
}