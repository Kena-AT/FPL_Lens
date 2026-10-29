import 'openai_compatible_adapter.dart';

class NvidiaNimAdapter extends OpenAiCompatibleAdapter {
  @override
  String get providerId => 'nvidia_nim';

  @override
  String get displayName => 'NVIDIA NIM';

  @override
  String get defaultModel => 'meta/llama-3.2-11b-vision-instruct';

  @override
  String get baseUrl => 'https://integrate.api.nvidia.com/v1/chat/completions';

  @override
  String get keyPrefix => 'nvapi-';
}
