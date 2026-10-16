import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/network/auth_interceptor.dart';
import 'package:fpl_lens/core/storage/secure_store.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStore extends Mock implements SecureStore {}
class MockDio extends Mock implements Dio {}
class MockErrorHandler extends Mock implements ErrorInterceptorHandler {}
class MockRequestHandler extends Mock implements RequestInterceptorHandler {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/api/v1/test'));
    registerFallbackValue(DioException(requestOptions: RequestOptions(path: '/api/v1/test')));
  });

  group('AuthInterceptor', () {
    late MockSecureStore mockSecureStore;
    late Dio dio;
    late AuthInterceptor interceptor;
    bool loggedOut = false;

    setUp(() {
      mockSecureStore = MockSecureStore();
      loggedOut = false;
      dio = Dio(BaseOptions(baseUrl: 'https://test.example.com'));
      interceptor = AuthInterceptor(
        dio: dio,
        secureStore: mockSecureStore,
        onUnauthenticated: () => loggedOut = true,
      );
    });

    test('Attaches Authorization header when accessToken is present', () {
      interceptor.accessToken = 'test-token-123';
      final options = RequestOptions(path: '/api/v1/profile');

      final handler = MockRequestHandler();
      when(() => handler.next(options)).thenReturn(null);
      interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer test-token-123');
      verify(() => handler.next(options)).called(1);
    });

    test('Does not attach Authorization header when accessToken is null', () {
      interceptor.accessToken = null;
      final options = RequestOptions(path: '/api/v1/profile');

      final handler = MockRequestHandler();
      when(() => handler.next(options)).thenReturn(null);
      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });

    test('Triggers onUnauthenticated on 401 when retried request fails again', () async {
      when(() => mockSecureStore.deleteRefreshToken()).thenAnswer((_) async {});

      final requestOptions = RequestOptions(
        path: '/api/v1/profile',
        extra: {'retried': true},
      );
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 401,
      );
      final error = DioException(
        requestOptions: requestOptions,
        response: response,
      );

      final handler = MockErrorHandler();
      when(() => handler.reject(any())).thenReturn(null);
      await interceptor.onError(error, handler);

      expect(loggedOut, isTrue);
      expect(interceptor.accessToken, isNull);
      verify(() => handler.reject(any())).called(1);
    });

    test('Triggers onUnauthenticated when refresh token is missing', () async {
      when(() => mockSecureStore.getRefreshToken()).thenAnswer((_) async => null);
      when(() => mockSecureStore.deleteRefreshToken()).thenAnswer((_) async {});

      final requestOptions = RequestOptions(path: '/api/v1/profile');
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 401,
      );
      final error = DioException(
        requestOptions: requestOptions,
        response: response,
      );

      final handler = MockErrorHandler();
      when(() => handler.reject(any())).thenReturn(null);
      await interceptor.onError(error, handler);

      expect(loggedOut, isTrue);
      verify(() => handler.reject(any())).called(1);
    });
  });
}
