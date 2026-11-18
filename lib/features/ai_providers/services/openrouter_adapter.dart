import 'openai_compatible_adapter.dart';

class OpenRouterAdapter extends OpenAiCompatibleAdapter {
  @override
  String get providerId => 'openrouter';

  @override
  String get displayName => 'OpenRouter';

  @override
  String get defaultModel => 'google/gemini-flash-1.5';

  @override
  String get baseUrl => 'https://openrouter.ai/api/v1/chat/completions';

  @override
  String get keyPrefix => 'sk-or-v1-';
}
