import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/network/error_mapper.dart';
import 'package:fpl_lens/core/storage/secure_store.dart';
import 'package:fpl_lens/data/models/user_model.dart';
import 'package:fpl_lens/data/repositories/auth_repository.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockSecureStore extends Mock implements SecureStore {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  late MockAuthRepository mockRepository;
  late MockSecureStore mockSecureStore;
  late AuthNotifier authNotifier;

  final testUser = UserModel(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test Manager',
    fplTeamId: 123456,
    status: 'active',
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    mockSecureStore = MockSecureStore();
    when(() => mockSecureStore.deleteSession()).thenAnswer((_) async {});
    when(() => mockSecureStore.saveLastActiveAt(any())).thenAnswer((_) async {});
    when(() => mockSecureStore.getLastActiveAt()).thenAnswer((_) async => null);
    when(() => mockSecureStore.getCachedUserJson()).thenAnswer((_) async => null);
    when(() => mockSecureStore.getUserId()).thenAnswer((_) async => null);
    when(() => mockSecureStore.getFplTeamId()).thenAnswer((_) async => null);

    authNotifier = AuthNotifier(
      repository: mockRepository,
      secureStore: mockSecureStore,
    );
  });

  group('Session Persistence & 7-Day Inactivity Window', () {
    test('Unauthenticated when no refresh token exists', () async {
      when(() => mockSecureStore.getRefreshToken()).thenAnswer((_) async => null);

      await authNotifier.checkSession();

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.user, isNull);
    });

    test('Logs out user and clears session if last active is 7 or more days ago', () async {
      when(() => mockSecureStore.getRefreshToken()).thenAnswer((_) async => 'valid-refresh-token');
      final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
      when(() => mockSecureStore.getLastActiveAt()).thenAnswer((_) async => eightDaysAgo);

      await authNotifier.checkSession();

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.errorMessage, contains('session expired'));
      verify(() => mockSecureStore.deleteSession()).called(1);
    });

    test('Restores session and refreshes active timestamp if entered within 7 days', () async {
      when(() => mockSecureStore.getRefreshToken()).thenAnswer((_) async => 'valid-refresh-token');
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      when(() => mockSecureStore.getLastActiveAt()).thenAnswer((_) async => threeDaysAgo);
      when(() => mockSecureStore.getCachedUserJson()).thenAnswer(
        (_) async => jsonEncode(testUser.toJson()),
      );
      when(() => mockRepository.getProfile()).thenAnswer((_) async => testUser);

      await authNotifier.checkSession();

      expect(authNotifier.state.status, AuthStatus.authenticatedVerified);
      expect(authNotifier.state.user?.id, 'user-123');
      expect(authNotifier.state.user?.email, 'test@example.com');
      verify(() => mockSecureStore.saveLastActiveAt(any())).called(greaterThanOrEqualTo(1));
    });

    test('Retains cached user authentication even when offline / network error', () async {
      when(() => mockSecureStore.getRefreshToken()).thenAnswer((_) async => 'valid-refresh-token');
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      when(() => mockSecureStore.getLastActiveAt()).thenAnswer((_) async => twoDaysAgo);
      when(() => mockSecureStore.getCachedUserJson()).thenAnswer(
        (_) async => jsonEncode(testUser.toJson()),
      );
      // Backend request fails with network error / timeout
      when(() => mockRepository.getProfile()).thenThrow(
        const AppError(kind: AppErrorKind.offline, message: 'No internet connection', retryable: true),
      );

      await authNotifier.checkSession();

      expect(authNotifier.state.status, AuthStatus.authenticatedVerified);
      expect(authNotifier.state.user?.id, 'user-123');
      // Did NOT delete session on network error
      verifyNever(() => mockSecureStore.deleteSession());
    });

    test('Clears session if server returns 401 unauthenticated during profile check', () async {
      when(() => mockSecureStore.getRefreshToken()).thenAnswer((_) async => 'revoked-token');
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      when(() => mockSecureStore.getLastActiveAt()).thenAnswer((_) async => oneDayAgo);
      when(() => mockSecureStore.getCachedUserJson()).thenAnswer(
        (_) async => jsonEncode(testUser.toJson()),
      );
      when(() => mockRepository.getProfile()).thenThrow(
        const AppError(kind: AppErrorKind.unauthenticated, message: 'Token revoked', retryable: false),
      );

      await authNotifier.checkSession();

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      verify(() => mockSecureStore.deleteSession()).called(1);
    });

    test('Logout clears session from secure storage', () async {
      when(() => mockRepository.logout()).thenAnswer((_) async {});

      await authNotifier.logout();

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      verify(() => mockSecureStore.deleteSession()).called(1);
    });
  });
}
