import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/extracted_player.dart';
import '../models/validation_result.dart';
import 'ai_provider_adapter.dart';

/// Adapter for Anthropic Claude Messages API via direct HTTP.
class ClaudeAdapter extends AiProviderAdapter {
  @override
  String get providerId => 'anthropic_claude';

  @override
  String get displayName => 'Anthropic Claude';

  @override
  String get defaultModel => 'claude-3-5-sonnet-20241022';

  @override
  bool validateKeyFormat(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith('sk-ant-');
  }

  @override
  Future<ValidationResult> validate(String key, Dio dio) async {
    if (!validateKeyFormat(key)) {
      return ValidationResult.failure(
        "That doesn't look like an Anthropic key. It typically starts with 'sk-ant-'.",
        'invalid_key',
      );
    }

    try {
      const url = 'https://api.anthropic.com/v1/messages';
      final response = await dio.post(
        url,
        data: {
          'model': defaultModel,
          'max_tokens': 15,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/png',
                    'data': kCapabilityTestImageBase64,
                  }
                },
                {'type': 'text', 'text': 'Describe this image in one word.'}
              ]
            }
          ]
        },
        options: Options(
          headers: {
            'x-api-key': key.trim(),
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        return ValidationResult.success();
      }
      return ValidationResult.failure('Key rejected by Anthropic.', 'invalid_key');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return ValidationResult.failure(
          'Anthropic Claude took too long to respond. Check your connection.',
          'timeout',
        );
      }
      final status = e.response?.statusCode;
      String? serverMsg;
      if (e.response?.data is Map) {
        final err = e.response?.data['error'];
        if (err is Map) {
          serverMsg = err['message'] as String?;
        }
      }
      if (status == 400 || status == 401 || status == 403) {
        return ValidationResult.failure(
          serverMsg ?? 'That key was rejected by Anthropic Claude. Check it and try again.',
          'invalid_key',
        );
      } else if (status == 429) {
        return ValidationResult.failure(
          serverMsg ?? 'Your Anthropic Claude key has reached its limit. Try again later.',
          'quota',
        );
      }
      return ValidationResult.failure(
        serverMsg ?? 'Could not validate Anthropic Claude key. Check your connection.',
        'network',
      );
    } catch (e) {
      return ValidationResult.failure('Validation failed: $e', 'invalid_key');
    }
  }

  @override
  Future<List<ExtractedPlayer>> extract({
    required Uint8List imageBytes,
    required String mimeType,
    required String key,
    required Dio dio,
    bool strict = false,
  }) async {
    final prompt = strict ? kSquadExtractionStrictPrompt : kSquadExtractionPrompt;
    const url = 'https://api.anthropic.com/v1/messages';

    final response = await dio.post(
      url,
      data: {
        'model': defaultModel,
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mimeType,
                  'data': base64Encode(imageBytes),
                }
              },
              {'type': 'text', 'text': prompt}
            ]
          }
        ]
      },
      options: Options(
        headers: {
          'x-api-key': key.trim(),
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final content = response.data['content'];
      if (content is List && content.isNotEmpty) {
        final text = content[0]['text'] as String? ?? '';
        return parsePlayersJson(text);
      }
    }
    return [];
  }
}
