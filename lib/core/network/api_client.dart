import 'package:dio/dio.dart';
import '../storage/secure_store.dart';
import 'auth_interceptor.dart';

enum AppFlavour {
  dev,
  prod,
}

class ApiClient {
  final Dio dio;
  final AuthInterceptor authInterceptor;
  final SecureStore secureStore;

  ApiClient._({
    required this.dio,
    required this.authInterceptor,
    required this.secureStore,
  });

  factory ApiClient({
    required String baseUrl,
    required SecureStore secureStore,
    OnUnauthenticatedCallback? onUnauthenticated,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final authInterceptor = AuthInterceptor(
      dio: dio,
      secureStore: secureStore,
      onUnauthenticated: onUnauthenticated,
    );

    dio.interceptors.add(authInterceptor);

    return ApiClient._(
      dio: dio,
      authInterceptor: authInterceptor,
      secureStore: secureStore,
    );
  }

  void setAccessToken(String? token) {
    authInterceptor.accessToken = token;
  }

  String? get accessToken => authInterceptor.accessToken;

  void clearSession() {
    authInterceptor.clearToken();
  }
}
