class MediaUrl {
  final String baseUrl;
  final String token;

  const MediaUrl({required this.baseUrl, required this.token});

  static String _encodeSegments(String path) {
    return path.split('/').where((s) => s.isNotEmpty).map(Uri.encodeComponent).join('/');
  }

  String _ownPath(String albumPath, String filename) {
    final album = _encodeSegments(albumPath);
    final file = Uri.encodeComponent(filename);
    return album.isEmpty
        ? '$baseUrl/api/files/my/$file'
        : '$baseUrl/api/files/my/$album/$file';
  }

  String _signed(String url) => '$url?token=$token';

  String ownImage(String albumPath, String filename) =>
      _signed(_ownPath(albumPath, filename));

  String ownThumb(String albumPath, String filename) =>
      _signed('${_ownPath(albumPath, filename)}/thumb');

  String sharedImage(int shareId, String filename) {
    final file = Uri.encodeComponent(filename);
    return _signed('$baseUrl/api/share/$shareId/files/$file');
  }

  String sharedThumb(int shareId, String filename) {
    final file = Uri.encodeComponent(filename);
    return _signed('$baseUrl/api/share/$shareId/thumb/$file');
  }
}
