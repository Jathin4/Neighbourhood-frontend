import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh tokens never touch shared_preferences — secure storage only
/// (Keychain/Keystore on mobile, encrypted storage on web/desktop backends).
class AuthStorage {
  static const _accessKey = 'tnn_access_token';
  static const _refreshKey = 'tnn_refresh_token';
  static const _userIdKey = 'tnn_user_id';
  static const _roleKey = 'tnn_role';

  final _storage = const FlutterSecureStorage();

  Future<void> saveSession({required String accessToken, required String refreshToken, required String userId, required String role}) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _roleKey, value: role);
  }

  Future<void> updateAccessToken(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> get accessToken => _storage.read(key: _accessKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);
  Future<String?> get userId => _storage.read(key: _userIdKey);
  Future<String?> get role => _storage.read(key: _roleKey);

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
