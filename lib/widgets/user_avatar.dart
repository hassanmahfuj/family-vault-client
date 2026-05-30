import 'package:flutter/material.dart';
import '../app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final double radius;

  const UserAvatar({
    super.key,
    required this.username,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      radius: radius,
      child: Text(
        username[0].toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
