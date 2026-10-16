import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_store.dart';

/// Callback when session cannot be recovered and user must be logged out.
typedef OnUnauthenticatedCallback = void Function();

/// Dio interceptor implementing Sprint 7 requirement:
/// Attaches access token, refreshes once on 401, and logs out on a second failure.
/// Refresh tokens stored in SecureStore; access token kept in memory only.
class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final SecureStore secureStore;
  OnUnauthenticatedCallback? onUnauthenticated;

  String? accessToken;
  bool _isRefreshing = false;

  AuthInterceptor({
    required this.dio,
    required this.secureStore,
    this.onUnauthenticated,
  });

  void clearToken() {
    accessToken = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (accessToken != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final path = err.requestOptions.path;

    // Do not attempt refresh on auth endpoints
    final isAuthEndpoint = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/google');

    if (response?.statusCode == 401 && !isAuthEndpoint) {
      final alreadyRetried = err.requestOptions.extra['retried'] == true;
      if (alreadyRetried) {
        // Second failure -> log out
        await _handleLogout();
        handler.reject(err);
        return;
      }

      if (_isRefreshing) {
        handler.reject(err);
        return;
      }

      _isRefreshing = true;

      try {
        final currentRefreshToken = await secureStore.getRefreshToken();
        if (currentRefreshToken == null) {
          await _handleLogout();
          handler.reject(err);
          return;
        }

        // Call refresh endpoint with a separate Dio instance to avoid interceptor recursion
        final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
        final refreshResponse = await refreshDio.post(
          '/api/v1/auth/refresh',
          data: {'refresh_token': currentRefreshToken},
        );

        if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
          final newAccessToken = refreshResponse.data['access_token'] as String;
          final newRefreshToken = refreshResponse.data['refresh_token'] as String;

          accessToken = newAccessToken;
          await secureStore.saveRefreshToken(newRefreshToken);

          // Retry the original failed request with the new access token
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          requestOptions.extra['retried'] = true;

          final retryResponse = await dio.fetch(requestOptions);
          handler.resolve(retryResponse);
          return;
        } else {
          await _handleLogout();
          handler.reject(err);
          return;
        }
      } catch (refreshErr) {
        await _handleLogout();
        handler.reject(err);
        return;
      } finally {
        _isRefreshing = false;
      }
    }

    handler.next(err);
  }

  Future<void> _handleLogout() async {
    accessToken = null;
    await secureStore.deleteRefreshToken();
    onUnauthenticated?.call();
  }
}
