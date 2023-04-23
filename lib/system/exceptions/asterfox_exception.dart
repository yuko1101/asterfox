class AsterfoxException implements Exception {
  AsterfoxException({required this.title, required this.description});
  final String title;
  final String description;
}
