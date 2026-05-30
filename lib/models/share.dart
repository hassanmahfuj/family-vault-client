class Share {
  final int id;
  final String ownerUsername;
  final String albumPath;
  final String albumName;
  final String sharedWith;
  final String permission;
  final String createdAt;

  const Share({
    required this.id,
    required this.ownerUsername,
    required this.albumPath,
    required this.albumName,
    required this.sharedWith,
    required this.permission,
    required this.createdAt,
  });

  factory Share.fromJson(Map<String, dynamic> json) {
    return Share(
      id: json['id'] as int,
      ownerUsername: json['ownerUsername'] as String? ?? '',
      albumPath: json['albumPath'] as String? ?? '',
      albumName: json['albumName'] as String? ?? json['albumPath'] as String? ?? '',
      sharedWith: json['sharedWith'] as String? ?? '',
      permission: json['permission'] as String? ?? 'VIEW',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  bool get canEdit => permission == 'EDIT';
  bool get isViewOnly => permission == 'VIEW';
}
