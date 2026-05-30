import 'package:flutter/material.dart';
import '../app_theme.dart';

class LoadingGrid extends StatelessWidget {
  final int itemCount;

  const LoadingGrid({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return _buildShimmerCard();
      },
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _shimmerBox(48, 48, AppRadius.md),
          const SizedBox(height: 12),
          _shimmerBox(80, 14, AppRadius.sm),
          const SizedBox(height: 6),
          _shimmerBox(50, 12, AppRadius.sm),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, double radius) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.6),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: value),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
      onEnd: () {},
    );
  }
}
