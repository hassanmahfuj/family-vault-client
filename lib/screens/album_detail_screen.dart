import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/file_item.dart';
import '../providers/file_provider.dart';
import '../services/api_service.dart';
import '../services/media_url.dart';
import '../widgets/album_card.dart';
import '../widgets/media_card.dart';
import '../widgets/loading_grid.dart';
import '../widgets/empty_state.dart';
import '../widgets/breadcrumb_trail.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/upload_bottom_sheet.dart';
import '../widgets/create_album_dialog.dart';
import '../widgets/share_album_dialog.dart';
import '../providers/share_provider.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumPath;
  final String albumName;

  const AlbumDetailScreen({
    super.key,
    required this.albumPath,
    required this.albumName,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  MediaUrl? _mediaUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileProvider>().loadContents(widget.albumPath);
      ApiService().resolveMediaUrl().then((u) {
        if (mounted) setState(() => _mediaUrl = u);
      });
    });
  }

  String? _thumbUrlFor(String albumPath, FileItem file) {
    if (file.isVideo || _mediaUrl == null) return null;
    return _mediaUrl!.ownThumb(albumPath, file.name);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.albumName),
            actions: [
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () => _showUploadSheet(provider),
                tooltip: 'Upload',
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, provider),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Share Album'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        SizedBox(width: 12),
                        Text('Delete Album', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              BreadcrumbTrail(
                currentPath: provider.currentPath,
                onNavigate: (path) {
                  if (path.isEmpty) {
                    Navigator.of(context).pop();
                  } else {
                    provider.loadContents(path);
                  }
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => provider.refresh(),
                  child: _buildBody(provider),
                ),
              ),
            ],
          ),
          floatingActionButton: provider.isLoading
              ? null
              : FloatingActionButton(
                  onPressed: () => _showAddOptions(provider),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  Widget _buildBody(FileProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const LoadingGrid();
    }

    if (provider.items.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'Empty album',
        subtitle: 'Add photos, videos, or create sub-albums',
        actionLabel: 'Upload',
        onAction: null,
      );
    }

    return CustomScrollView(
      slivers: [
        if (provider.albums.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final album = provider.albums[index];
                  return AlbumCard(
                    album: album,
                    onTap: () => _navigateToSubAlbum(album),
                    onLongPress: () => _showAlbumOptions(provider, album),
                  );
                },
                childCount: provider.albums.length,
              ),
            ),
          ),
        if (provider.mediaFiles.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final file = provider.mediaFiles[index];
                  return MediaCard(
                    file: file,
                    thumbnailUrl: _thumbUrlFor(provider.currentPath, file),
                    onTap: () => _openMedia(provider, file),
                    onLongPress: () => _showFileOptions(provider, file),
                  );
                },
                childCount: provider.mediaFiles.length,
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _navigateToSubAlbum(FileItem album) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FileProvider>(),
          child: AlbumDetailScreen(
            albumPath: album.path,
            albumName: album.name,
          ),
        ),
      ),
    );
    if (mounted) {
      context.read<FileProvider>().loadContents(widget.albumPath);
    }
  }

  void _openMedia(FileProvider provider, FileItem file) {
    if (file.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            file: file,
            albumPath: provider.currentPath,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerScreen(
            file: file,
            albumPath: provider.currentPath,
            allFiles: provider.mediaFiles,
            mediaUrl: _mediaUrl,
          ),
        ),
      );
    }
  }

  void _showAddOptions(FileProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('New Sub-Album'),
              onTap: () {
                Navigator.pop(context);
                _showCreateAlbum(provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload Files'),
              onTap: () {
                Navigator.pop(context);
                _showUploadSheet(provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAlbum(FileProvider provider) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const CreateAlbumDialog(),
    );
    if (name != null && name.isNotEmpty) {
      final success = await provider.createAlbum(name);
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create album')),
        );
      }
    }
  }

  void _showUploadSheet(FileProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => UploadBottomSheet(
        albumPath: provider.currentPath,
        onUploadComplete: () => provider.refresh(),
      ),
    );
  }

  void _handleMenuAction(String action, FileProvider provider) async {
    if (action == 'delete') {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Delete Album',
        message: 'Delete "${widget.albumName}" and all its contents?',
      );
      if (confirmed == true) {
        final parentPath = widget.albumPath.contains('/')
            ? widget.albumPath.substring(0, widget.albumPath.lastIndexOf('/'))
            : '';
        await provider.deleteAlbum(widget.albumPath);
        if (mounted) {
          Navigator.of(context).pop();
          provider.loadContents(parentPath);
        }
      }
    } else if (action == 'share') {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => ShareAlbumDialog(albumName: widget.albumName),
      );
      if (result != null) {
        final shareProvider = context.read<ShareProvider>();
        final error = await shareProvider.shareAlbum(
          widget.albumPath,
          result['username']!,
          result['permission']!,
        );
        if (mounted && error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    }
  }

  void _showAlbumOptions(FileProvider provider, FileItem album) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Album', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await ConfirmDialog.show(
                  this.context,
                  title: 'Delete Album',
                  message: 'Delete "${album.name}" and all its contents?',
                );
                if (confirmed == true) {
                  await provider.deleteAlbum(album.path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFileOptions(FileProvider provider, FileItem file) {
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
                  await provider.deleteFile(provider.currentPath, file.name);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
