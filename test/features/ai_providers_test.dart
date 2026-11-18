import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/storage/secure_store.dart';
import 'package:fpl_lens/features/ai_providers/services/ai_provider_registry.dart';
import 'package:fpl_lens/features/ai_providers/services/claude_adapter.dart';
import 'package:fpl_lens/features/ai_providers/services/gemini_adapter.dart';
import 'package:fpl_lens/features/ai_providers/services/grok_adapter.dart';
import 'package:fpl_lens/features/ai_providers/services/nvidia_nim_adapter.dart';
import 'package:fpl_lens/features/ai_providers/services/openai_adapter.dart';
import 'package:fpl_lens/features/ai_providers/services/openrouter_adapter.dart';

void main() {
  group('AI Provider Adapters & Key Format Tests', () {
    test('Registry contains all 6 supported providers', () {
      final adapters = AiProviderRegistry.adapters;
      expect(adapters.length, 6);

      final ids = adapters.map((a) => a.providerId).toSet();
      expect(
        ids,
        containsAll([
          'google_gemini',
          'anthropic_claude',
          'openai',
          'xai_grok',
          'nvidia_nim',
          'openrouter',
        ]),
      );

      for (final a in adapters) {
        expect(a.supportsVision(), isTrue);
      }
    });

    test('GeminiAdapter key format validation', () {
      final adapter = GeminiAdapter();
      expect(adapter.validateKeyFormat('AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz12345'), isTrue);
      expect(adapter.validateKeyFormat('shortKey'), isFalse);
      expect(adapter.validateKeyFormat(''), isFalse);
    });

    test('ClaudeAdapter key format validation', () {
      final adapter = ClaudeAdapter();
      expect(adapter.validateKeyFormat('sk-ant-api03-abcdefghijklmn'), isTrue);
      expect(adapter.validateKeyFormat('sk-openai-key'), isFalse);
      expect(adapter.validateKeyFormat(''), isFalse);
    });

    test('OpenAiAdapter key format validation', () {
      final adapter = OpenAiAdapter();
      expect(adapter.validateKeyFormat('sk-proj-1234567890abcdef'), isTrue);
      expect(adapter.validateKeyFormat('xai-12345'), isFalse);
      expect(adapter.validateKeyFormat(''), isFalse);
    });

    test('GrokAdapter key format validation', () {
      final adapter = GrokAdapter();
      expect(adapter.validateKeyFormat('xai-1234567890abcdef'), isTrue);
      expect(adapter.validateKeyFormat('sk-12345'), isFalse);
    });

    test('NvidiaNimAdapter key format validation', () {
      final adapter = NvidiaNimAdapter();
      expect(adapter.validateKeyFormat('nvapi-1234567890abcdef'), isTrue);
      expect(adapter.validateKeyFormat('sk-12345'), isFalse);
    });

    test('OpenRouterAdapter key format validation', () {
      final adapter = OpenRouterAdapter();
      expect(adapter.validateKeyFormat('sk-or-v1-abcdef123456'), isTrue);
      expect(adapter.validateKeyFormat('sk-ant-12345'), isFalse);
    });

    test('parsePlayersJson extracts JSON correctly even with markdown fences', () {
      final adapter = GeminiAdapter();

      const rawJson = '''
```json
{
  "players": [
    {"raw_name": "Haaland", "slot": "FWD"},
    {"raw_name": "Salah", "slot": "MID"},
    {"raw_name": "Raya", "slot": "GK"}
  ]
}
```
''';
      final players = adapter.parsePlayersJson(rawJson);
      expect(players.length, 3);
      expect(players[0].rawName, 'Haaland');
      expect(players[0].slot, 'FWD');
      expect(players[1].rawName, 'Salah');
      expect(players[1].slot, 'MID');
      expect(players[2].rawName, 'Raya');
      expect(players[2].slot, 'GK');
    });

    test('parsePlayersJson returns empty list on invalid JSON without throwing', () {
      final adapter = GeminiAdapter();
      final players = adapter.parsePlayersJson('I could not read the screenshot.');
      expect(players, isEmpty);
    });
  });

  group('AI Key Secure Storage & Masking Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('saves, retrieves, masks, and removes AI key', () async {
      final secureStore = SecureStore();

      expect(await secureStore.hasAiKey(), isFalse);
      expect(await secureStore.getAiKey(), isNull);
      expect(await secureStore.getMaskedAiKey(), isNull);

      final testKey = 'AIzaSyTestKey1234567890abcdefABCDEF';
      await secureStore.saveAiKey(
        providerId: 'google_gemini',
        key: testKey,
        validatedAt: DateTime(2026, 10, 23, 12, 0),
      );

      expect(await secureStore.hasAiKey(), isTrue);
      expect(await secureStore.getAiProvider(), 'google_gemini');
      expect(await secureStore.getAiKey(), testKey);

      // Masked key must show only bullet points and last 4 characters
      final masked = await secureStore.getMaskedAiKey();
      expect(masked, '••••••••CDEF');

      final validatedAt = await secureStore.getAiValidatedAt();
      expect(validatedAt, isNotNull);
      expect(validatedAt!.year, 2026);

      // Remove key
      await secureStore.deleteAiKey();
      expect(await secureStore.hasAiKey(), isFalse);
      expect(await secureStore.getAiKey(), isNull);
      expect(await secureStore.getAiProvider(), isNull);
      expect(await secureStore.getMaskedAiKey(), isNull);
    });
  });
}
