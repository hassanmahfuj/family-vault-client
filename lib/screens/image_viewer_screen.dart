import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/file_item.dart';
import '../services/api_service.dart';

class ImageViewerScreen extends StatefulWidget {
  final FileItem file;
  final String albumPath;
  final List<FileItem> allFiles;

  const ImageViewerScreen({
    super.key,
    required this.file,
    required this.albumPath,
    required this.allFiles,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final ApiService _apiService = ApiService();
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

  String _encodePath(String path) {
    return path.split('/').map(Uri.encodeComponent).join('/');
  }

  Widget _buildImage(FileItem file) {
    final encodedAlbum = _encodePath(widget.albumPath);
    final endpoint = encodedAlbum.isEmpty
        ? '/api/files/my/${Uri.encodeComponent(file.name)}'
        : '/api/files/my/$encodedAlbum/${Uri.encodeComponent(file.name)}';

    return Center(
      child: FutureBuilder(
        future: _apiService.authenticatedRequest(endpoint),
        builder: (context, AsyncSnapshot<dynamic> snap) {
          if (!snap.hasData) {
            return const CircularProgressIndicator(color: AppColors.primary);
          }
          if (snap.hasError) {
            return const Icon(Icons.error_outline, color: AppColors.error, size: 48);
          }
          final response = snap.data;
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(
              response.bodyBytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          );
        },
      ),
    );
  }
}
