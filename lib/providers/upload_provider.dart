import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/media_service.dart';

class UploadTask {
  final String filename;
  final double progress;
  final String? error;
  final bool isComplete;

  const UploadTask({
    required this.filename,
    this.progress = 0,
    this.error,
    this.isComplete = false,
  });

  UploadTask copyWith({
    double? progress,
    String? error,
    bool? isComplete,
  }) {
    return UploadTask(
      filename: filename,
      progress: progress ?? this.progress,
      error: error,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class UploadProvider extends ChangeNotifier {
  final MediaService _mediaService = MediaService();

  List<UploadTask> _tasks = [];
  bool _isUploading = false;

  List<UploadTask> get tasks => _tasks;
  bool get isUploading => _isUploading;
  bool get allComplete => _tasks.isNotEmpty && _tasks.every((t) => t.isComplete);

  void setFiles(List<String> filenames) {
    _tasks = filenames
        .map((f) => UploadTask(filename: f))
        .toList();
    notifyListeners();
  }

  void removeTask(int index) {
    if (index >= 0 && index < _tasks.length) {
      _tasks.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> upload(String albumPath, List<http.MultipartFile> files) async {
    _isUploading = true;
    notifyListeners();

    for (int i = 0; i < files.length; i++) {
      _tasks[i] = _tasks[i].copyWith(progress: 0.1);
      notifyListeners();

      try {
        await _mediaService.uploadFiles(
          albumPath,
          [files[i]],
          onProgress: (progress) {
            _tasks[i] = _tasks[i].copyWith(progress: progress);
            notifyListeners();
          },
        );
        _tasks[i] = _tasks[i].copyWith(progress: 1.0, isComplete: true);
      } catch (e) {
        _tasks[i] = _tasks[i].copyWith(
          error: e.toString().replaceFirst('Exception: ', ''),
          isComplete: true,
        );
      }
      notifyListeners();
    }

    _isUploading = false;
    notifyListeners();
  }

  void clear() {
    _tasks = [];
    _isUploading = false;
    notifyListeners();
  }
}
