import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../app_theme.dart';
import '../providers/upload_provider.dart';

class UploadBottomSheet extends StatefulWidget {
  final String albumPath;
  final VoidCallback onUploadComplete;

  const UploadBottomSheet({
    super.key,
    required this.albumPath,
    required this.onUploadComplete,
  });

  @override
  State<UploadBottomSheet> createState() => _UploadBottomSheetState();
}

class _UploadBottomSheetState extends State<UploadBottomSheet> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickFiles();
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );

    if (result == null || result.files.isEmpty) {
      if (!mounted) return;
      if (context.read<UploadProvider>().tasks.isEmpty) {
        Navigator.of(context).pop();
      }
      return;
    }

    final provider = context.read<UploadProvider>();
    final files = result.files.where((f) => f.path != null).toList();
    provider.setFiles(files.map((f) => f.name).toList());

    final multipartFiles = <http.MultipartFile>[];
    for (final file in files) {
      multipartFiles.add(
        await http.MultipartFile.fromPath('files', file.path!),
      );
    }

    await provider.upload(widget.albumPath, multipartFiles);

    if (mounted && provider.allComplete) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        widget.onUploadComplete();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UploadProvider>(
      builder: (context, uploadProvider, _) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Text(
                      'Upload Files',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              if (uploadProvider.tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: GestureDetector(
                    onTap: _pickFiles,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.border,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to select files',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: uploadProvider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = uploadProvider.tasks[index];
                      return _buildTaskItem(task, index, uploadProvider);
                    },
                  ),
                ),
              if (uploadProvider.tasks.isNotEmpty && !uploadProvider.isUploading)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: uploadProvider.allComplete
                          ? () {
                              widget.onUploadComplete();
                              Navigator.of(context).pop();
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        uploadProvider.allComplete ? 'Done' : 'Uploading...',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(UploadTask task, int index, UploadProvider provider) {
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
            Icon(
              task.isComplete && task.error == null
                  ? Icons.check_circle
                  : task.error != null
                      ? Icons.error
                      : Icons.insert_drive_file_outlined,
              size: 20,
              color: task.isComplete && task.error == null
                  ? AppColors.success
                  : task.error != null
                      ? AppColors.error
                      : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.filename,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.isComplete && task.error != null)
                    Text(
                      task.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    )
                  else if (!task.isComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: task.progress,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!provider.isUploading)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => provider.removeTask(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
