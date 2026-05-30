import 'package:flutter/foundation.dart';
import '../models/auth_response.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _serverAddress;
  String? _username;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  String? get serverAddress => _serverAddress;
  String? get username => _username;

  Future<void> loadServerAddress() async {
    _serverAddress = await _tokenStorage.getServerAddress();
    notifyListeners();
  }

  Future<void> saveServerAddress(String address) async {
    await _tokenStorage.saveServerAddress(address);
    _serverAddress = address;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _serverAddress = await _tokenStorage.getServerAddress();
    final hasTokens = await _tokenStorage.hasTokens();
    if (hasTokens && _serverAddress != null && _serverAddress!.isNotEmpty) {
      try {
        await _apiService.refreshToken();
        _isAuthenticated = true;
      } catch (_) {
        _isAuthenticated = false;
      }
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    if (_serverAddress == null || _serverAddress!.isEmpty) {
      _error = 'Server address not configured';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AuthResponse response = await _apiService.login(username, password);
      await _tokenStorage.saveTokens(response.accessToken, response.refreshToken);
      _username = username;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    _isAuthenticated = false;
    notifyListeners();
  }
}
