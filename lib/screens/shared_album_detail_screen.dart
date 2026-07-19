import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/file_item.dart';
import '../models/share.dart';
import '../services/api_service.dart';
import '../services/media_url.dart';
import '../widgets/album_card.dart';
import '../widgets/media_card.dart';
import '../widgets/loading_grid.dart';
import '../widgets/empty_state.dart';
import '../widgets/confirm_dialog.dart';
import '../services/media_service.dart';
import 'video_player_screen.dart';

class SharedAlbumDetailScreen extends StatefulWidget {
  final Share share;

  const SharedAlbumDetailScreen({super.key, required this.share});

  @override
  State<SharedAlbumDetailScreen> createState() => _SharedAlbumDetailScreenState();
}

class _SharedAlbumDetailScreenState extends State<SharedAlbumDetailScreen> {
  final MediaService _mediaService = MediaService();
  List<FileItem> _items = [];
  bool _isLoading = true;
  String? _error;
  MediaUrl? _mediaUrl;

  @override
  void initState() {
    super.initState();
    _loadContents();
    ApiService().resolveMediaUrl().then((u) {
      if (mounted) setState(() => _mediaUrl = u);
    });
  }

  Future<void> _loadContents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _items = await _mediaService.listSharedContents(widget.share.id);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    setState(() => _isLoading = false);
  }

  String? _thumbUrlFor(FileItem file) {
    if (file.isVideo || _mediaUrl == null) return null;
    return _mediaUrl!.sharedThumb(widget.share.id, file.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.share.albumName),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _loadContents,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingGrid();

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load',
        subtitle: _error,
        actionLabel: 'Retry',
        onAction: _loadContents,
      );
    }

    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'Empty album',
        subtitle: 'No files in this shared album',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        if (item.isAlbum) {
          return AlbumCard(
            album: item,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SharedAlbumDetailScreen(
                    share: Share(
                      id: widget.share.id,
                      ownerUsername: widget.share.ownerUsername,
                      albumPath: item.path,
                      albumName: item.name,
                      sharedWith: widget.share.sharedWith,
                      permission: widget.share.permission,
                      createdAt: widget.share.createdAt,
                    ),
                  ),
                ),
              );
            },
          );
        }
        return MediaCard(
          file: item,
          thumbnailUrl: _thumbUrlFor(item),
          onTap: () => _openMedia(item),
          onLongPress: widget.share.canEdit
              ? () => _showFileOptions(item)
              : null,
        );
      },
    );
  }

  void _openMedia(FileItem file) {
    if (file.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            file: file,
            albumPath: widget.share.albumPath,
            isShared: true,
            shareId: widget.share.id,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _SharedImageViewer(
            file: file,
            share: widget.share,
            allFiles: _items.where((i) => i.isMedia).toList(),
            mediaUrl: _mediaUrl,
          ),
        ),
      );
    }
  }

  void _showFileOptions(FileItem file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await ConfirmDialog.show(
                  this.context,
                  title: 'Delete File',
                  message: 'Delete "${file.name}"?',
                );
                if (confirmed == true) {
                  await _mediaService.deleteSharedFile(widget.share.id, file.name);
                  _loadContents();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedImageViewer extends StatelessWidget {
  final FileItem file;
  final Share share;
  final List<FileItem> allFiles;
  final MediaUrl? mediaUrl;

  const _SharedImageViewer({
    required this.file,
    required this.share,
    required this.allFiles,
    required this.mediaUrl,
  });

  @override
  Widget build(BuildContext context) {
    final images = allFiles.where((f) => f.type == FileItemType.image).toList();
    final currentIndex = images.indexWhere((f) => f.name == file.name);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${(currentIndex < 0 ? 0 : currentIndex) + 1} of ${images.length}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Center(
        child: mediaUrl == null
            ? const CircularProgressIndicator(color: AppColors.primary)
            : InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: mediaUrl!.sharedImage(share.id, file.name),
                  cacheKey: 'image:${file.path}',
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                ),
              ),
      ),
    );
  }
}
