import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/share.dart';
import '../providers/share_provider.dart';
import '../widgets/user_avatar.dart';
import '../widgets/permission_badge.dart';
import '../widgets/empty_state.dart';
import 'shared_album_detail_screen.dart';

class SharedWithMeScreen extends StatefulWidget {
  const SharedWithMeScreen({super.key});

  @override
  State<SharedWithMeScreen> createState() => _SharedWithMeScreenState();
}

class _SharedWithMeScreenState extends State<SharedWithMeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShareProvider>().loadSharedWithMe();
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
            onRefresh: () => provider.loadSharedWithMe(),
            child: _buildBody(provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(ShareProvider provider) {
    if (provider.isLoading && provider.sharedWithMe.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.sharedWithMe.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No shared albums',
        subtitle: 'Albums shared with you will appear here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.sharedWithMe.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final share = provider.sharedWithMe[index];
        return _buildShareCard(share);
      },
    );
  }

  Widget _buildShareCard(Share share) {
    return Card(
      child: InkWell(
        onTap: () => _openSharedAlbum(share),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatar(username: share.ownerUsername, radius: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      share.albumName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shared by ${share.ownerUsername}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PermissionBadge(permission: share.permission),
            ],
          ),
        ),
      ),
    );
  }

  void _openSharedAlbum(Share share) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharedAlbumDetailScreen(share: share),
      ),
    );
  }
}
