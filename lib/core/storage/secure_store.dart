import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper per Sprint 7 requirements.
/// Stores only the refresh token and necessary persistent identifiers.
/// Access tokens are kept in memory only and NEVER stored here.
class SecureStore {
  final FlutterSecureStorage _storage;

  static const String _keyRefreshToken = 'fpl_refresh_token';
  static const String _keyUserId = 'fpl_user_id';
  static const String _keyFplTeamId = 'fpl_team_id';

  static const String _keyAiProvider = 'fpl_ai_provider';
  static const String _keyAiKey = 'fpl_ai_key';
  static const String _keyAiValidatedAt = 'fpl_ai_validated_at';

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

  // --- AI Key Storage (Sprint 11) ---

  Future<void> saveAiKey({
    required String providerId,
    required String key,
    DateTime? validatedAt,
  }) async {
    await _storage.write(key: _keyAiProvider, value: providerId);
    await _storage.write(key: _keyAiKey, value: key.trim());
    if (validatedAt != null) {
      await _storage.write(
        key: _keyAiValidatedAt,
        value: validatedAt.toIso8601String(),
      );
    }
  }

  Future<String?> getAiProvider() async {
    return await _storage.read(key: _keyAiProvider);
  }

  Future<String?> getAiKey() async {
    return await _storage.read(key: _keyAiKey);
  }

  Future<DateTime?> getAiValidatedAt() async {
    final val = await _storage.read(key: _keyAiValidatedAt);
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  Future<String?> getMaskedAiKey() async {
    final key = await getAiKey();
    if (key == null || key.isEmpty) return null;
    if (key.length <= 4) return '••••';
    final last4 = key.substring(key.length - 4);
    return '••••••••$last4';
  }

  Future<void> deleteAiKey() async {
    await _storage.delete(key: _keyAiProvider);
    await _storage.delete(key: _keyAiKey);
    await _storage.delete(key: _keyAiValidatedAt);
  }

  Future<bool> hasAiKey() async {
    final key = await _storage.read(key: _keyAiKey);
    return key != null && key.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
