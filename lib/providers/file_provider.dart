import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/media_service.dart';

class FileProvider extends ChangeNotifier {
  final MediaService _mediaService = MediaService();

  List<FileItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String _currentPath = '';

  List<FileItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentPath => _currentPath;

  List<FileItem> get albums => _items.where((i) => i.isAlbum).toList();
  List<FileItem> get mediaFiles => _items.where((i) => i.isMedia).toList();

  Future<void> loadContents(String albumPath) async {
    _currentPath = albumPath;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _mediaService.listContents(albumPath);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadContents(_currentPath);
  }

  Future<bool> createAlbum(String name) async {
    try {
      final path = _currentPath.isEmpty ? name : '$_currentPath/$name';
      await _mediaService.createAlbum(path);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAlbum(String albumPath) async {
    try {
      await _mediaService.deleteAlbum(albumPath);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFile(String albumPath, String filename) async {
    try {
      await _mediaService.deleteFile(albumPath, filename);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  void clear() {
    _items = [];
    _currentPath = '';
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
