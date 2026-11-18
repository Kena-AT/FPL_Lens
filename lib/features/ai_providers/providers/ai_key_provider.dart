import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/ai_provider_registry.dart';

class AiKeyState {
  final String? providerId;
  final String? maskedKey;
  final DateTime? validatedAt;
  final bool isConfigured;
  final bool isValidating;
  final String? errorMessage;
  final String? successMessage;

  const AiKeyState({
    this.providerId,
    this.maskedKey,
    this.validatedAt,
    this.isConfigured = false,
    this.isValidating = false,
    this.errorMessage,
    this.successMessage,
  });

  AiKeyState copyWith({
    String? providerId,
    String? maskedKey,
    DateTime? validatedAt,
    bool? isConfigured,
    bool? isValidating,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AiKeyState(
      providerId: providerId ?? this.providerId,
      maskedKey: maskedKey ?? this.maskedKey,
      validatedAt: validatedAt ?? this.validatedAt,
      isConfigured: isConfigured ?? this.isConfigured,
      isValidating: isValidating ?? this.isValidating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AiKeyNotifier extends StateNotifier<AiKeyState> {
  final SecureStore _secureStore;
  final Dio _dio;

  AiKeyNotifier({
    required SecureStore secureStore,
    Dio? dio,
  })  : _secureStore = secureStore,
        _dio = dio ?? Dio(),
        super(const AiKeyState()) {
    loadStoredKey();
  }

  Future<void> loadStoredKey() async {
    final providerId = await _secureStore.getAiProvider();
    final maskedKey = await _secureStore.getMaskedAiKey();
    final validatedAt = await _secureStore.getAiValidatedAt();
    final hasKey = await _secureStore.hasAiKey();

    state = state.copyWith(
      providerId: providerId,
      maskedKey: maskedKey,
      validatedAt: validatedAt,
      isConfigured: hasKey,
    );
  }

  Future<bool> validateAndSave({
    required String providerId,
    required String rawKey,
  }) async {
    state = state.copyWith(
      isValidating: true,
      clearError: true,
      clearSuccess: true,
    );

    final adapter = AiProviderRegistry.getAdapter(providerId);
    if (adapter == null) {
      state = state.copyWith(
        isValidating: false,
        errorMessage: 'Unsupported AI provider.',
      );
      return false;
    }

    if (!adapter.validateKeyFormat(rawKey)) {
      state = state.copyWith(
        isValidating: false,
        errorMessage: "That doesn't look like a ${adapter.displayName} key.",
      );
      return false;
    }

    final result = await adapter.validate(rawKey, _dio);
    if (!result.isValid) {
      // Log failure message without exposing raw key
      // ignore: avoid_print
      print('AI Key validation failed for provider $providerId: ${result.errorMessage}');
      state = state.copyWith(
        isValidating: false,
        errorMessage: result.errorMessage ?? 'Key validation failed.',
      );
      return false;
    }

    final now = DateTime.now();
    await _secureStore.saveAiKey(
      providerId: providerId,
      key: rawKey,
      validatedAt: now,
    );

    final masked = await _secureStore.getMaskedAiKey();

    state = state.copyWith(
      providerId: providerId,
      maskedKey: masked,
      validatedAt: now,
      isConfigured: true,
      isValidating: false,
      successMessage: 'Key saved. Stored only on this phone.',
    );
    return true;
  }

  Future<void> removeKey() async {
    await _secureStore.deleteAiKey();
    state = const AiKeyState(
      isConfigured: false,
      successMessage: 'Key removed.',
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final aiKeyProvider = StateNotifierProvider<AiKeyNotifier, AiKeyState>((ref) {
  final secureStore = ref.watch(secureStoreProvider);
  return AiKeyNotifier(secureStore: secureStore);
});
