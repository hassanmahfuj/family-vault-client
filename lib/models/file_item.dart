enum FileItemType { album, image, video }

class FileItem {
  final String name;
  final String path;
  final FileItemType type;
  final int? size;
  final int? itemCount;
  final String? modifiedDate;
  final String? mimeType;

  const FileItem({
    required this.name,
    required this.path,
    required this.type,
    this.size,
    this.itemCount,
    this.modifiedDate,
    this.mimeType,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';
    FileItemType type;
    if (typeStr == 'album') {
      type = FileItemType.album;
    } else if (typeStr == 'video') {
      type = FileItemType.video;
    } else {
      type = FileItemType.image;
    }

    return FileItem(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      type: type,
      size: json['size'] as int?,
      itemCount: json['itemCount'] as int?,
      modifiedDate: json['modifiedDate'] as String?,
      mimeType: json['mimeType'] as String?,
    );
  }

  String get displaySize {
    if (size == null) return '';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    if (size! < 1024 * 1024 * 1024) {
      return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get isVideo => type == FileItemType.video;
  bool get isAlbum => type == FileItemType.album;
  bool get isMedia => type == FileItemType.image || type == FileItemType.video;
}
