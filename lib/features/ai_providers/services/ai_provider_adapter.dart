import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/extracted_player.dart';
import '../models/validation_result.dart';

/// Base64 encoded 100x100 red PNG image used for the capability vision check
/// per Frontend Implementation Plan §8.3 (meets all provider vision minimum size bounds).
const String kCapabilityTestImageBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAIAAAD/gAIDAAAAkElEQVR42u3QMQ0AAAjAsPk3DRb4eJpUQZviSIEsWbJkyUKBLFmyZMlCgSxZsmTJQoEsWbJkyUKBLFmyZMlCgSxZsmTJQoEsWbJkyUKBLFmyZMlCgSxZsmTJQoEsWbJkyUKBLFmyZMlCgSxZsmTJQoEsWbJkyUKBLFmyZMlCgSxZsmTJQoEsWbJkyUKBLFnvFp4t6yugc3LNAAAAAElFTkSuQmCC';

/// Extraction prompt for extracting squad players from an FPL screenshot.
const String kSquadExtractionPrompt =
    'You are an assistant reading a Fantasy Premier League (FPL) screenshot. '
    'Extract all 15 player names along with their pitch or bench slot (GK, DEF, MID, FWD, or SUB). '
    'Return ONLY valid JSON in the format: {"players": [{"raw_name": "...", "slot": "..."}]} with no markdown fences and no extra text.';

/// Stricter extraction prompt on retry.
const String kSquadExtractionStrictPrompt =
    'CRITICAL: Return ONLY valid JSON with no markdown code fences, no formatting backticks, and no explanation. '
    'Schema: {"players": [{"raw_name": "Player Name", "slot": "GK|DEF|MID|FWD|SUB"}]}. '
    'List all visible squad players.';

/// Abstract adapter for supported AI vision providers.
/// Direct HTTP requests via Dio with no vendor SDKs.
abstract class AiProviderAdapter {
  String get providerId;
  String get displayName;
  String get defaultModel;

  bool supportsVision() => true;

  bool validateKeyFormat(String key);

  Future<ValidationResult> validate(String key, Dio dio);

  Future<List<ExtractedPlayer>> extract({
    required Uint8List imageBytes,
    required String mimeType,
    required String key,
    required Dio dio,
    bool strict = false,
  });

  Future<String> generateText({
    required String prompt,
    required String key,
    required Dio dio,
  }) async => '';

  /// Helper to parse players array from AI output string.
  List<ExtractedPlayer> parsePlayersJson(String content) {
    // Strip markdown code fences if present
    String cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.length > 2) {
        cleaned = lines.sublist(1, lines.length - 1).join('\n').trim();
      }
    }
    // Also strip single backticks
    if (cleaned.startsWith('`') && cleaned.endsWith('`')) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }

    try {
      final startIndex = cleaned.indexOf('{');
      final endIndex = cleaned.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex + 1);
      }
      final dynamic parsed = jsonDecode(cleaned);
      if (parsed is Map<String, dynamic>) {
        final playersList = parsed['players'] ?? parsed['squad'];
        if (playersList is List) {
          return playersList
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return ExtractedPlayer.fromJson(item);
                } else if (item is String) {
                  return ExtractedPlayer(rawName: item);
                }
                return null;
              })
              .whereType<ExtractedPlayer>()
              .toList();
        }
      }
    } catch (_) {
      // JSON parse error
    }
    return [];
  }
}
