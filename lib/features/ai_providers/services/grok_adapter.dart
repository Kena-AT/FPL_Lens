import 'openai_compatible_adapter.dart';

class GrokAdapter extends OpenAiCompatibleAdapter {
  @override
  String get providerId => 'xai_grok';

  @override
  String get displayName => 'xAI Grok';

  @override
  String get defaultModel => 'grok-2-vision-1212';

  @override
  String get baseUrl => 'https://api.x.ai/v1/chat/completions';

  @override
  String get keyPrefix => 'xai-';
}
