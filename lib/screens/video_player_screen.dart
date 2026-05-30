import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../app_theme.dart';
import '../models/file_item.dart';
import '../services/token_storage.dart';

class VideoPlayerScreen extends StatefulWidget {
  final FileItem file;
  final String albumPath;
  final bool isShared;
  final int? shareId;

  const VideoPlayerScreen({
    super.key,
    required this.file,
    required this.albumPath,
    this.isShared = false,
    this.shareId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  final TokenStorage _tokenStorage = TokenStorage();
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;

  String _encodePath(String path) {
    return path.split('/').map(Uri.encodeComponent).join('/');
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final baseUrl = await _tokenStorage.getServerAddress();
      final token = await _tokenStorage.getAccessToken();
      if (baseUrl == null || token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      String path;
      if (widget.isShared && widget.shareId != null) {
        path = '/api/share/${widget.shareId}/stream/${Uri.encodeComponent(widget.file.name)}';
      } else {
        final encodedAlbum = _encodePath(widget.albumPath);
        path = encodedAlbum.isEmpty
            ? '/api/files/my/${Uri.encodeComponent(widget.file.name)}/stream'
            : '/api/files/my/$encodedAlbum/${Uri.encodeComponent(widget.file.name)}/stream';
      }

      final videoUrl = '$baseUrl$path?token=$token';
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      _controller.addListener(() {
        if (_controller.value.hasError) {
          setState(() {
            _error = 'Playback error';
            _isLoading = false;
          });
        }
      });

      await _controller.initialize();
      setState(() {
        _isLoading = false;
      });
      _controller.play();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showControls = false);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.file.name,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Center(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const CircularProgressIndicator(color: AppColors.primary);
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _initVideo();
            },
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          if (_showControls) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, VideoPlayerValue value, _) {
              return VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: AppColors.primary.withValues(alpha: 0.3),
                  backgroundColor: AppColors.border,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, VideoPlayerValue value, _) {
                    return Text(
                      '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  onPressed: () {
                    final pos = _controller.value.position - const Duration(seconds: 10);
                    _controller.seekTo(pos < Duration.zero ? Duration.zero : pos);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  onPressed: () {
                    final pos = _controller.value.position + const Duration(seconds: 10);
                    _controller.seekTo(pos > _controller.value.duration ? _controller.value.duration : pos);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
