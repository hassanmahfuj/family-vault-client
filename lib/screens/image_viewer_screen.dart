import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/file_item.dart';
import '../services/media_url.dart';

class ImageViewerScreen extends StatefulWidget {
  final FileItem file;
  final String albumPath;
  final List<FileItem> allFiles;
  final MediaUrl? mediaUrl;

  const ImageViewerScreen({
    super.key,
    required this.file,
    required this.albumPath,
    required this.allFiles,
    this.mediaUrl,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showBars = true;

  List<FileItem> get _images =>
      widget.allFiles.where((f) => f.type == FileItemType.image).toList();

  @override
  void initState() {
    super.initState();
    _currentIndex = _images.indexWhere((f) => f.name == widget.file.name);
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showBars
          ? AppBar(
              backgroundColor: Colors.black,
              title: Text(
                '${_currentIndex + 1} of ${_images.length}',
                style: const TextStyle(fontSize: 14),
              ),
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showBars = !_showBars),
        child: PageView.builder(
          controller: _pageController,
          itemCount: _images.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            return _buildImage(_images[index]);
          },
        ),
      ),
      bottomNavigationBar: _showBars && _images.length > 1
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _images.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentIndex
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildImage(FileItem file) {
    if (widget.mediaUrl == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    final imageUrl = widget.mediaUrl!.ownImage(widget.albumPath, file.name);
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          cacheKey: 'image:${file.path}',
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 100),
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          errorWidget: (_, __, ___) => const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
        ),
      ),
    );
  }
}
