import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _serverAddressKey = 'server_address';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> hasTokens() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    return accessToken != null;
  }

  Future<String?> getServerAddress() async {
    return await _storage.read(key: _serverAddressKey);
  }

  Future<void> saveServerAddress(String address) async {
    await _storage.write(key: _serverAddressKey, value: address);
  }

  Future<bool> hasServerAddress() async {
    final address = await _storage.read(key: _serverAddressKey);
    return address != null && address.isNotEmpty;
  }
}
