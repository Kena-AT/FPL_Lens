import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/extracted_player.dart';
import '../models/validation_result.dart';
import 'ai_provider_adapter.dart';

/// Base adapter for providers implementing the OpenAI-compatible chat completions API.
abstract class OpenAiCompatibleAdapter extends AiProviderAdapter {
  String get baseUrl;
  String get keyPrefix;

  @override
  bool validateKeyFormat(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith(keyPrefix);
  }

  @override
  Future<ValidationResult> validate(String key, Dio dio) async {
    if (!validateKeyFormat(key)) {
      return ValidationResult.failure(
        "That doesn't look like a $displayName key. It typically starts with '$keyPrefix'.",
        'invalid_key',
      );
    }

    try {
      final response = await dio.post(
        baseUrl,
        data: {
          'model': defaultModel,
          'max_tokens': 15,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': 'Describe this image in one word.'},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/png;base64,$kCapabilityTestImageBase64'
                  }
                }
              ]
            }
          ]
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${key.trim()}',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        return ValidationResult.success();
      }
      return ValidationResult.failure('Key rejected by $displayName.', 'invalid_key');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return ValidationResult.failure(
          '$displayName took too long to respond. Check your connection.',
          'timeout',
        );
      }
      final status = e.response?.statusCode;
      String? serverMsg;
      if (e.response?.data is Map) {
        final err = e.response?.data['error'];
        if (err is Map) {
          serverMsg = err['message'] as String?;
        } else if (err is String) {
          serverMsg = err;
        }
      }
      if (status == 400 || status == 401 || status == 403) {
        return ValidationResult.failure(
          serverMsg ?? 'That key was rejected by $displayName. Check it and try again.',
          'invalid_key',
        );
      } else if (status == 429) {
        return ValidationResult.failure(
          serverMsg ?? 'Your $displayName key has reached its limit. Try again later.',
          'quota',
        );
      }
      return ValidationResult.failure(
        serverMsg ?? 'Could not validate $displayName key. Check your connection.',
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
    final b64 = base64Encode(imageBytes);

    final response = await dio.post(
      baseUrl,
      data: {
        'model': defaultModel,
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mimeType;base64,$b64'}
              }
            ]
          }
        ]
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${key.trim()}',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final choices = response.data['choices'];
      if (choices is List && choices.isNotEmpty) {
        final message = choices[0]['message'];
        if (message != null && message['content'] != null) {
          final content = message['content'] as String;
          return parsePlayersJson(content);
        }
      }
    }
    return [];
  }
  @override
  Future<String> generateText({
    required String prompt,
    required String key,
    required Dio dio,
  }) async {
    final response = await dio.post(
      baseUrl,
      data: {
        'model': defaultModel,
        'max_tokens': 500,
        'messages': [
          {'role': 'user', 'content': prompt}
        ]
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${key.trim()}',
          'Content-Type': 'application/json',
        },
      ),
    );
    final choices = response.data['choices'] as List?;
    if (choices != null && choices.isNotEmpty) {
      return choices[0]['message']?['content'] as String? ?? '';
    }
    return '';
  }
}
