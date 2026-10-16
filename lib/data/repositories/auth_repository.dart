import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/error_mapper.dart';
import '../../core/storage/secure_store.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStore secureStore;

  AuthRepository({
    required this.apiClient,
    required this.secureStore,
  });

  Dio get _dio => apiClient.dio;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/auth/login',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final data = res.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      apiClient.setAccessToken(accessToken);
      await secureStore.saveRefreshToken(refreshToken);

      return await getProfile();
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required int fplTeamId,
  }) async {
    try {
      await _dio.post(
        '/api/v1/auth/register',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'display_name': displayName.trim(),
          'fpl_team_id': fplTeamId,
        },
      );
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  Future<UserModel> verifyEmail(String code) async {
    try {
      final res = await _dio.post(
        '/api/v1/auth/verify-email',
        data: {'code': code.trim()},
      );

      final data = res.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      apiClient.setAccessToken(accessToken);
      await secureStore.saveRefreshToken(refreshToken);

      return await getProfile();
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  Future<void> resendVerificationCode() async {
    try {
      await _dio.post('/api/v1/auth/verify-email/resend');
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  Future<UserModel> signInWithGoogle({
    required String idToken,
    int? fplTeamId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/auth/google',
        data: {
          'id_token': idToken,
          if (fplTeamId != null) 'fpl_team_id': fplTeamId,
        },
      );

      final data = res.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      apiClient.setAccessToken(accessToken);
      await secureStore.saveRefreshToken(refreshToken);

      return await getProfile();
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final res = await _dio.get('/api/v1/me');
      final user = UserModel.fromJson(res.data as Map<String, dynamic>);
      if (user.fplTeamId != null) {
        await secureStore.saveFplTeamId(user.fplTeamId!);
      }
      await secureStore.saveUserId(user.id);
      return user;
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  Future<void> registerDevice(String fcmToken) async {
    try {
      await _dio.post(
        '/api/v1/devices',
        data: {
          'fcm_token': fcmToken,
          'platform': 'android',
        },
      );
    } catch (e) {
      // Non-blocking device registration
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/api/v1/me');
    } finally {
      apiClient.clearSession();
      await secureStore.clearAll();
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await secureStore.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post(
          '/api/v1/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      apiClient.clearSession();
      await secureStore.clearAll();
    }
  }
}
