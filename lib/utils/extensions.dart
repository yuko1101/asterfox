final _httpRegex = RegExp(r'^https?:\/\/.+$');

extension StringExtension on String {
  bool get isUrl => _httpRegex.hasMatch(this);
}