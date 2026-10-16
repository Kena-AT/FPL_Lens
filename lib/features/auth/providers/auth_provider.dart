import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/storage/secure_store.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  authenticatedUnverified,
  authenticatedVerified,
  locked,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final int? lockoutSeconds;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.lockoutSeconds,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticatedVerified ||
      status == AuthStatus.authenticatedUnverified;

  bool get isVerified =>
      status == AuthStatus.authenticatedVerified && (user?.isEmailVerified ?? false);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    int? lockoutSeconds,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      lockoutSeconds: lockoutSeconds ?? this.lockoutSeconds,
    );
  }
}

final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore();
});

final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig(
    flavor: AppFlavor.dev,
    apiBaseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: 'https://fpl-lens-dev.onrender.com'),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStore = ref.watch(secureStoreProvider);
  final config = ref.watch(appConfigProvider);
  return ApiClient(
    baseUrl: config.apiBaseUrl,
    secureStore: secureStore,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStore = ref.watch(secureStoreProvider);
  return AuthRepository(apiClient: apiClient, secureStore: secureStore);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStore _secureStore;
  Timer? _lockoutTimer;

  AuthNotifier({
    required AuthRepository repository,
    required SecureStore secureStore,
  })  : _repository = repository,
        _secureStore = secureStore,
        super(const AuthState(status: AuthStatus.initial));

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void handleSessionExpired() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: "Please sign in again.",
    );
  }

  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final refreshToken = await _secureStore.getRefreshToken();
      if (refreshToken == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final user = await _repository.getProfile();
      if (!user.isEmailVerified) {
        state = AuthState(status: AuthStatus.authenticatedUnverified, user: user);
      } else {
        state = AuthState(status: AuthStatus.authenticatedVerified, user: user);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.login(email: email, password: password);
      if (!user.isEmailVerified) {
        state = AuthState(status: AuthStatus.authenticatedUnverified, user: user);
      } else {
        state = AuthState(status: AuthStatus.authenticatedVerified, user: user);
      }
      return true;
    } on AppError catch (e) {
      if (e.kind == AppErrorKind.rateLimited) {
        _startLockout(15 * 60);
        state = AuthState(
          status: AuthStatus.locked,
          errorMessage: "Too many attempts. Try again in 15 minutes.",
          lockoutSeconds: 15 * 60,
        );
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: "Email or password is incorrect.",
        );
      }
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: "Email or password is incorrect.",
      );
      return false;
    }
  }

  void _startLockout(int seconds) {
    _lockoutTimer?.cancel();
    int remaining = seconds;
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(status: AuthStatus.unauthenticated, lockoutSeconds: null);
      } else {
        state = state.copyWith(lockoutSeconds: remaining);
      }
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required int fplTeamId,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
        fplTeamId: fplTeamId,
      );
      // Backend automatically sent code. Create temporary user object for verify screen.
      final tempUser = UserModel(
        id: '',
        email: email,
        displayName: displayName,
        fplTeamId: fplTeamId,
        status: 'unverified',
      );
      state = AuthState(status: AuthStatus.authenticatedUnverified, user: tempUser);
      return true;
    } on AppError catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: "Registration failed. Try again.",
      );
      return false;
    }
  }

  Future<bool> verifyEmail(String code) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.verifyEmail(code);
      state = AuthState(status: AuthStatus.authenticatedVerified, user: user);
      return true;
    } on AppError catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticatedUnverified,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.authenticatedUnverified,
        errorMessage: "Verification failed. Try again.",
      );
      return false;
    }
  }

  Future<void> resendVerificationCode() async {
    try {
      await _repository.resendVerificationCode();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signInWithGoogle(String idToken, {int? fplTeamId}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signInWithGoogle(idToken: idToken, fplTeamId: fplTeamId);
      state = AuthState(status: AuthStatus.authenticatedVerified, user: user);
      return true;
    } on AppError catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: "Google sign-in failed. Try again.",
      );
      return false;
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.deleteAccount();
    } finally {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: "Your account is scheduled for deletion. You can sign in again within 3 days to cancel.",
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.logout();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final secureStore = ref.watch(secureStoreProvider);
  final apiClient = ref.watch(apiClientProvider);
  final notifier = AuthNotifier(repository: repository, secureStore: secureStore);
  apiClient.authInterceptor.onUnauthenticated = notifier.handleSessionExpired;
  return notifier;
});
