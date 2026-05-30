import 'package:flutter/material.dart';
import '../models/share.dart';
import '../services/media_service.dart';

class ShareProvider extends ChangeNotifier {
  final MediaService _mediaService = MediaService();

  List<Share> _myShares = [];
  List<Share> _sharedWithMe = [];
  bool _isLoading = false;
  String? _error;

  List<Share> get myShares => _myShares;
  List<Share> get sharedWithMe => _sharedWithMe;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSharedWithMe() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sharedWithMe = await _mediaService.getSharedWithMe();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _sharedWithMe = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyShares() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myShares = await _mediaService.getMyShares();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _myShares = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> shareAlbum(String albumPath, String sharedWith, String permission) async {
    try {
      await _mediaService.shareAlbum(albumPath, sharedWith, permission);
      await loadMyShares();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> revokeShare(int shareId) async {
    try {
      await _mediaService.revokeShare(shareId);
      await loadMyShares();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
