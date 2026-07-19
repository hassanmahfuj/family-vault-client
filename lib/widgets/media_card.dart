import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/file_item.dart';

class MediaCard extends StatelessWidget {
  final FileItem file;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? thumbnailUrl;

  const MediaCard({
    super.key,
    required this.file,
    required this.onTap,
    this.onLongPress,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildPreview(),
                  if (file.isVideo)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VIDEO',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (file.size != null)
                    Text(
                      file.displaySize,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (thumbnailUrl != null && !file.isVideo) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl!,
        cacheKey: 'thumb:${file.path}',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => Container(
          color: AppColors.surfaceElevated,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _iconFallback(),
      );
    }
    return _iconFallback();
  }

  Widget _iconFallback() {
    return Container(
      color: AppColors.surfaceElevated,
      child: Center(
        child: file.isVideo
            ? const Icon(
                Icons.play_circle_outline,
                color: AppColors.secondary,
                size: 40,
              )
            : const Icon(
                Icons.image_outlined,
                color: AppColors.textMuted,
                size: 40,
              ),
      ),
    );
  }
}
