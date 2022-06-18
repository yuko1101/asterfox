class LocalSongNotFoundException implements Exception {
  LocalSongNotFoundException(this.audioId);
  final String audioId;
  @override
  String toString() => 'LocalSongNotFoundException: $audioId';
}
