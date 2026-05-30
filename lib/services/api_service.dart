import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../services/token_storage.dart';

class ApiService {
  final TokenStorage _tokenStorage = TokenStorage();

  Future<String?> getBaseUrl() async {
    return await _tokenStorage.getServerAddress();
  }

  Future<String?> getAccessToken() async {
    return await _tokenStorage.getAccessToken();
  }

  Future<AuthResponse> login(String username, String password) async {
    final baseUrl = await getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Server address not configured');
    }

    http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
    } catch (e) {
      throw Exception('Cannot connect to server');
    }

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    }

    try {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    } on FormatException {
      throw Exception('Login failed');
    }
  }

  Future<AuthResponse> refreshToken() async {
    final baseUrl = await getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Server address not configured');
    }

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await http.post(
      Uri.parse('$baseUrl${ApiConfig.refreshEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refreshToken': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _tokenStorage.saveTokens(authResponse.accessToken, authResponse.refreshToken);
      return authResponse;
    }

    await _tokenStorage.clearTokens();
    throw Exception('Session expired. Please login again.');
  }

  Future<http.Response> authenticatedRequest(String endpoint, {String method = 'GET', Map<String, dynamic>? body}) async {
    var accessToken = await _tokenStorage.getAccessToken();

    var response = await _sendRequest(endpoint, accessToken!, method: method, body: body);

    if (response.statusCode == 401) {
      try {
        final newAuth = await refreshToken();
        response = await _sendRequest(endpoint, newAuth.accessToken, method: method, body: body);
      } catch (_) {
        throw Exception('Session expired. Please login again.');
      }
    }

    return response;
  }

  Future<http.Response> _sendRequest(String endpoint, String token, {String method = 'GET', Map<String, dynamic>? body}) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    switch (method.toUpperCase()) {
      case 'POST':
        return await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'PUT':
        return await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        return await http.get(uri, headers: headers);
    }
  }
}
