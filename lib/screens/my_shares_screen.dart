import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/share.dart';
import '../providers/share_provider.dart';
import '../widgets/user_avatar.dart';
import '../widgets/permission_badge.dart';
import '../widgets/empty_state.dart';
import '../widgets/confirm_dialog.dart';

class MySharesScreen extends StatefulWidget {
  const MySharesScreen({super.key});

  @override
  State<MySharesScreen> createState() => _MySharesScreenState();
}

class _MySharesScreenState extends State<MySharesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShareProvider>().loadMyShares();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShareProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () => provider.loadMyShares(),
            child: _buildBody(provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(ShareProvider provider) {
    if (provider.isLoading && provider.myShares.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.myShares.isEmpty) {
      return const EmptyState(
        icon: Icons.share_outlined,
        title: 'No shared albums',
        subtitle: 'Share an album from your files to see it here',
      );
    }

    final grouped = <String, List<Share>>{};
    for (final share in provider.myShares) {
      final key = share.albumPath;
      grouped.putIfAbsent(key, () => []).add(share);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        final albumPath = entry.key;
        final shares = entry.value;
        final albumName = albumPath.split('/').last;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      albumName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ...shares.map((share) => _buildShareItem(share, provider)),
            const Divider(color: AppColors.border),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildShareItem(Share share, ShareProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            UserAvatar(username: share.sharedWith, radius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    share.sharedWith,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  PermissionBadge(permission: share.permission),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
              onPressed: () => _revokeShare(share, provider),
              tooltip: 'Revoke access',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revokeShare(Share share, ShareProvider provider) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Revoke Access',
      message: 'Remove ${share.sharedWith}\'s access to this album?',
    );
    if (confirmed == true) {
      final error = await provider.revokeShare(share.id);
      if (mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }
}
