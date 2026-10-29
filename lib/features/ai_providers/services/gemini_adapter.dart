import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/extracted_player.dart';
import '../models/validation_result.dart';
import 'ai_provider_adapter.dart';

/// Adapter for Google Gemini API via direct HTTP.
class GeminiAdapter extends AiProviderAdapter {
  @override
  String get providerId => 'google_gemini';

  @override
  String get displayName => 'Google Gemini';

  @override
  String get defaultModel => 'gemini-3.5-flash-lite';

  @override
  @override
  bool validateKeyFormat(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith('AIzaSy') && trimmed.length >= 20;
  }

  @override
  Future<ValidationResult> validate(String key, Dio dio) async {
    if (!validateKeyFormat(key)) {
      return ValidationResult.failure(
        "That doesn't look like a Google Gemini key. It typically starts with 'AIzaSy'.",
        'invalid_key',
      );
    }

    ValidationResult result = await _tryValidateModel(defaultModel, key, dio);
    if (!result.isValid && defaultModel != 'gemini-1.5-flash') {
      // If default model is unavailable or not found, fallback to stable gemini-1.5-flash
      final fallbackResult = await _tryValidateModel('gemini-1.5-flash', key, dio);
      if (fallbackResult.isValid) {
        return fallbackResult;
      }
    }
    return result;
  }

  Future<ValidationResult> _tryValidateModel(String model, String key, Dio dio) async {
    try {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${key.trim()}';

      final response = await dio.post(
        url,
        data: {
          'contents': [
            {
              'parts': [
                {'text': 'Respond with ONE word: what color is this image?'},
                {
                  'inlineData': {
                    'mimeType': 'image/png',
                    'data': kCapabilityTestImageBase64,
                  }
                }
              ]
            }
          ],
          'generationConfig': {'maxOutputTokens': 10},
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        return ValidationResult.success();
      }
      return ValidationResult.failure('Key rejected by Google Gemini.', 'invalid_key');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return ValidationResult.failure(
          'Google Gemini took too long to respond. Check your connection.',
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
          serverMsg ?? 'That key was rejected by Google Gemini. Check it and try again.',
          'invalid_key',
        );
      } else if (status == 404) {
        return ValidationResult.failure(
          serverMsg ?? 'Model $model not found. Check availability for your key.',
          'invalid_key',
        );
      } else if (status == 429) {
        return ValidationResult.failure(
          serverMsg ?? 'Your Google Gemini key has reached its limit. Try again later.',
          'quota',
        );
      }
      return ValidationResult.failure(
        serverMsg ?? 'Could not validate Google Gemini key. Check your connection.',
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
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$defaultModel:generateContent?key=${key.trim()}';

    final response = await dio.post(
      url,
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Encode(imageBytes),
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
        },
      },
      options: Options(
        sendTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final candidates = response.data['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        if (content != null && content['parts'] is List && (content['parts'] as List).isNotEmpty) {
          final text = content['parts'][0]['text'] as String? ?? '';
          return parsePlayersJson(text);
        }
      }
    }
    return [];
  }
}
