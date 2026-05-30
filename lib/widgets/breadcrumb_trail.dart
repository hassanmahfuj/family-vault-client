import 'package:flutter/material.dart';
import '../app_theme.dart';

class BreadcrumbTrail extends StatelessWidget {
  final String currentPath;
  final void Function(String path) onNavigate;

  const BreadcrumbTrail({
    super.key,
    required this.currentPath,
    required this.onNavigate,
  });

  List<String> get _segments => currentPath.split('/').where((s) => s.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    if (_segments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSegment('My Files', '', isFirst: true),
            ..._segments.asMap().entries.expand((entry) {
              final index = entry.key;
              final segment = entry.value;
              final path = _segments.sublist(0, index + 1).join('/');
              return [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                _buildSegment(
                  segment,
                  path,
                  isLast: index == _segments.length - 1,
                ),
              ];
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String label, String path, {bool isFirst = false, bool isLast = false}) {
    return InkWell(
      onTap: isLast ? null : () => onNavigate(path),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          isFirst ? label : label,
          style: TextStyle(
            color: isLast ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
