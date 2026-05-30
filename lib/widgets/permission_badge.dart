import 'package:flutter/material.dart';
import '../app_theme.dart';

class PermissionBadge extends StatelessWidget {
  final String permission;

  const PermissionBadge({super.key, required this.permission});

  @override
  Widget build(BuildContext context) {
    final isEdit = permission == 'EDIT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isEdit ? AppColors.success : AppColors.primary)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEdit ? Icons.edit_outlined : Icons.visibility_outlined,
            size: 12,
            color: isEdit ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            isEdit ? 'Can Edit' : 'Can View',
            style: TextStyle(
              color: isEdit ? AppColors.success : AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
