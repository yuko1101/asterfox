class InvalidTypeOfMediaUrlException implements Exception {
  InvalidTypeOfMediaUrlException(this.mediaUrl);
  final String mediaUrl;
  @override
  String toString() => 'InvalidTypeOfMediaUrlException: $mediaUrl';
}
