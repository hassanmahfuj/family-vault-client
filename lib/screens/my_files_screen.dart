import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/file_provider.dart';
import '../models/file_item.dart';
import '../widgets/album_card.dart';
import '../widgets/media_card.dart';
import '../widgets/loading_grid.dart';
import '../widgets/empty_state.dart';
import '../widgets/create_album_dialog.dart';
import '../widgets/upload_bottom_sheet.dart';
import '../widgets/confirm_dialog.dart';
import 'album_detail_screen.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';

class MyFilesScreen extends StatefulWidget {
  const MyFilesScreen({super.key});

  @override
  State<MyFilesScreen> createState() => _MyFilesScreenState();
}

class _MyFilesScreenState extends State<MyFilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileProvider>().loadContents('');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () => provider.refresh(),
            child: _buildBody(provider),
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

    if (provider.error != null && provider.items.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: provider.error,
        actionLabel: 'Retry',
        onAction: () => provider.refresh(),
      );
    }

    if (provider.items.isEmpty) {
      return EmptyState(
        icon: Icons.folder_outlined,
        title: 'No files yet',
        subtitle: 'Upload photos and videos to get started',
        actionLabel: 'Upload',
        onAction: () => _showUploadSheet(provider),
      );
    }

    return CustomScrollView(
      slivers: [
        if (provider.albums.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Albums',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ),
        if (provider.albums.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    onTap: () => _navigateToAlbum(album.path),
                    onLongPress: () => _showAlbumOptions(provider, album),
                  );
                },
                childCount: provider.albums.length,
              ),
            ),
          ),
        if (provider.mediaFiles.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Files',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

  void _navigateToAlbum(String albumPath) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FileProvider>(),
          child: AlbumDetailScreen(
            albumPath: albumPath,
            albumName: albumPath.split('/').last,
          ),
        ),
      ),
    );
    if (mounted) {
      context.read<FileProvider>().loadContents('');
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
              title: const Text('New Album'),
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

  void _showAlbumOptions(FileProvider provider, album) {
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
                  message: 'Are you sure you want to delete "${album.name}" and all its contents?',
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

  void _showFileOptions(FileProvider provider, file) {
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
                  message: 'Are you sure you want to delete "${file.name}"?',
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
