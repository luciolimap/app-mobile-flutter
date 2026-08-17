import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps secure, encrypted storage for the auth token and cached user info.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'access_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userRoleKey = 'user_role';

  Future<void> saveSession({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
    required String userRole,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userNameKey, value: userName);
    await _storage.write(key: _userEmailKey, value: userEmail);
    await _storage.write(key: _userRoleKey, value: userRole);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readUserId() => _storage.read(key: _userIdKey);

  Future<String?> readUserName() => _storage.read(key: _userNameKey);

  Future<String?> readUserEmail() => _storage.read(key: _userEmailKey);

  Future<String?> readUserRole() => _storage.read(key: _userRoleKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userRoleKey);
  }
}
