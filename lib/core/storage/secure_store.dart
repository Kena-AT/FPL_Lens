import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper per Sprint 7 requirements.
/// Stores only the refresh token and necessary persistent identifiers.
/// Access tokens are kept in memory only and NEVER stored here.
class SecureStore {
  final FlutterSecureStorage _storage;

  static const String _keyRefreshToken = 'fpl_refresh_token';
  static const String _keyUserId = 'fpl_user_id';
  static const String _keyFplTeamId = 'fpl_team_id';

  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _keyRefreshToken);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  Future<void> saveFplTeamId(int teamId) async {
    await _storage.write(key: _keyFplTeamId, value: teamId.toString());
  }

  Future<int?> getFplTeamId() async {
    final val = await _storage.read(key: _keyFplTeamId);
    if (val == null) return null;
    return int.tryParse(val);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
