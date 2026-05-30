import 'package:flutter/material.dart';
import '../app_theme.dart';

class ShareAlbumDialog extends StatefulWidget {
  final String albumName;

  const ShareAlbumDialog({super.key, required this.albumName});

  @override
  State<ShareAlbumDialog> createState() => _ShareAlbumDialogState();
}

class _ShareAlbumDialogState extends State<ShareAlbumDialog> {
  final _usernameController = TextEditingController();
  String _permission = 'VIEW';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Share "${widget.albumName}"'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _usernameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter username to share with',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Permission',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _permission = 'VIEW'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _permission == 'VIEW'
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _permission == 'VIEW'
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: _permission == 'VIEW'
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View',
                            style: TextStyle(
                              color: _permission == 'VIEW'
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontWeight: _permission == 'VIEW'
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _permission = 'EDIT'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _permission == 'EDIT'
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _permission == 'EDIT'
                              ? AppColors.success
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: _permission == 'EDIT'
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: _permission == 'EDIT'
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              fontWeight: _permission == 'EDIT'
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Share'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'username': _usernameController.text.trim(),
        'permission': _permission,
      });
    }
  }
}
