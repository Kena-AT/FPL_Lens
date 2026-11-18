import 'ai_provider_adapter.dart';
import 'claude_adapter.dart';
import 'gemini_adapter.dart';
import 'grok_adapter.dart';
import 'nvidia_nim_adapter.dart';
import 'openai_adapter.dart';
import 'openrouter_adapter.dart';

class AiProviderRegistry {
  static final List<AiProviderAdapter> adapters = [
    GeminiAdapter(),
    ClaudeAdapter(),
    OpenAiAdapter(),
    GrokAdapter(),
    NvidiaNimAdapter(),
    OpenRouterAdapter(),
  ];

  static AiProviderAdapter? getAdapter(String providerId) {
    try {
      return adapters.firstWhere((a) => a.providerId == providerId);
    } catch (_) {
      return null;
    }
  }
}
