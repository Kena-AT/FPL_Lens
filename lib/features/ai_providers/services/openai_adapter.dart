import 'openai_compatible_adapter.dart';

class OpenAiAdapter extends OpenAiCompatibleAdapter {
  @override
  String get providerId => 'openai';

  @override
  String get displayName => 'OpenAI';

  @override
  String get defaultModel => 'gpt-4o-mini';

  @override
  String get baseUrl => 'https://api.openai.com/v1/chat/completions';

  @override
  String get keyPrefix => 'sk-';
}
