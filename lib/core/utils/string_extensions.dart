extension StringUrlExtension on String {
  bool get isUrl {
    try {
      final uri = Uri.parse(this);
      return uri.hasAbsolutePath && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
