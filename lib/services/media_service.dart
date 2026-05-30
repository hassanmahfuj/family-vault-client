import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/file_item.dart';
import '../models/share.dart';
import '../services/api_service.dart';

class MediaService {
  final ApiService _apiService = ApiService();

  String _encodePath(String path) {
    return path.split('/').map(Uri.encodeComponent).join('/');
  }

  Future<List<FileItem>> listContents(String albumPath) async {
    final endpoint = albumPath.isEmpty
        ? '/api/files/my'
        : '/api/files/my/${_encodePath(albumPath)}';
    final response = await _apiService.authenticatedRequest(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> items = jsonDecode(response.body);
      return items.map((item) => FileItem.fromJson(item as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load contents');
  }

  Future<void> createAlbum(String albumPath) async {
    final response = await _apiService.authenticatedRequest(
      '/api/files/my/${_encodePath(albumPath)}',
      method: 'POST',
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create album');
    }
  }

  Future<void> deleteAlbum(String albumPath) async {
    final response = await _apiService.authenticatedRequest(
      '/api/files/my/${_encodePath(albumPath)}',
      method: 'DELETE',
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete album');
    }
  }

  Future<void> deleteFile(String albumPath, String filename) async {
    final encodedAlbum = _encodePath(albumPath);
    final endpoint = encodedAlbum.isEmpty
        ? '/api/files/my/${Uri.encodeComponent(filename)}'
        : '/api/files/my/$encodedAlbum/${Uri.encodeComponent(filename)}';
    final response = await _apiService.authenticatedRequest(
      endpoint,
      method: 'DELETE',
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete file');
    }
  }

  Future<double> uploadFiles(
    String albumPath,
    List<http.MultipartFile> files, {
    void Function(double progress)? onProgress,
  }) async {
    final baseUrl = await _apiService.getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Server address not configured');
    }
    final token = await _apiService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final path = albumPath.isEmpty
        ? '/api/files/my/upload'
        : '/api/files/my/${_encodePath(albumPath)}/upload';
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.addAll(files);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      onProgress?.call(1.0);
      return 1.0;
    }

    throw Exception('Upload failed');
  }

  Future<Share> shareAlbum(String albumPath, String sharedWith, String permission) async {
    final response = await _apiService.authenticatedRequest(
      '/api/share',
      method: 'POST',
      body: {
        'albumPath': albumPath,
        'sharedWith': sharedWith,
        'permission': permission,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Share.fromJson(jsonDecode(response.body));
    }

    try {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to share album');
    } on FormatException {
      throw Exception('Failed to share album');
    }
  }

  Future<void> revokeShare(int shareId) async {
    final response = await _apiService.authenticatedRequest(
      '/api/share/$shareId',
      method: 'DELETE',
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to revoke share');
    }
  }

  Future<List<Share>> getMyShares() async {
    final response = await _apiService.authenticatedRequest('/api/share/my-shares');
    if (response.statusCode == 200) {
      final List<dynamic> items = jsonDecode(response.body);
      return items.map((item) => Share.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load shares');
  }

  Future<List<Share>> getSharedWithMe() async {
    final response = await _apiService.authenticatedRequest('/api/share/shared-with-me');
    if (response.statusCode == 200) {
      final List<dynamic> items = jsonDecode(response.body);
      return items.map((item) => Share.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load shared albums');
  }

  Future<List<FileItem>> listSharedContents(int shareId) async {
    final response = await _apiService.authenticatedRequest('/api/share/$shareId/files');
    if (response.statusCode == 200) {
      final List<dynamic> items = jsonDecode(response.body);
      return items.map((item) => FileItem.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load shared contents');
  }

  Future<void> deleteSharedFile(int shareId, String filename) async {
    final response = await _apiService.authenticatedRequest(
      '/api/share/$shareId/files/${Uri.encodeComponent(filename)}',
      method: 'DELETE',
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete file');
    }
  }

  Future<double> uploadToShared(
    int shareId,
    List<http.MultipartFile> files, {
    void Function(double progress)? onProgress,
  }) async {
    final baseUrl = await _apiService.getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Server address not configured');
    }
    final token = await _apiService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl/api/share/$shareId/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.addAll(files);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      onProgress?.call(1.0);
      return 1.0;
    }

    throw Exception('Upload failed');
  }
}
