import 'package:flutter_riverpod/flutter_riverpod.dart';

class CrashReportSanitizer {
  static final RegExp emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp keyPattern = RegExp(
    r'(AIza[0-9A-Za-z-_]{35}|sk-[a-zA-Z0-9]{20,}|ant-[a-zA-Z0-9]{20,})',
  );

  static final RegExp bearerPattern = RegExp(
    r'Bearer\s+[a-zA-Z0-9\-_\.]+',
    caseSensitive: false,
  );

  static const List<String> sensitiveHeaders = [
    'authorization',
    'x-job-token',
    'cookie',
    'set-cookie',
    'proxy-authorization',
  ];

  static const List<String> sensitiveKeys = [
    'password',
    'access_token',
    'refresh_token',
    'code',
    'api_key',
    'secret',
    'key',
    'token',
    'squad',
    'picks',
  ];

  static String scrubString(String input) {
    var output = input;
    output = output.replaceAll(bearerPattern, 'Bearer [REDACTED]');
    output = output.replaceAll(keyPattern, '[REDACTED_KEY]');
    output = output.replaceAll(emailPattern, '[REDACTED_EMAIL]');
    return output;
  }

  static Map<String, dynamic> sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, dynamic>{};
    for (final entry in headers.entries) {
      if (sensitiveHeaders.contains(entry.key.toLowerCase())) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        sanitized[entry.key] = scrubString(entry.value.toString());
      }
    }
    return sanitized;
  }

  static String sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.hasQuery) {
        final clean = uri.replace(query: '').toString();
        return clean.endsWith('?') ? clean.substring(0, clean.length - 1) : clean;
      }
      return url;
    } catch (_) {
      return scrubString(url);
    }
  }

  static dynamic sanitizeData(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      return scrubString(data);
    }
    if (data is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in data.entries) {
        final keyStr = entry.key.toString();
        if (sensitiveKeys.contains(keyStr.toLowerCase())) {
          sanitized[keyStr] = '[REDACTED]';
        } else {
          sanitized[keyStr] = sanitizeData(entry.value);
        }
      }
      return sanitized;
    }
    if (data is Iterable) {
      return data.map((item) => sanitizeData(item)).toList();
    }
    return data;
  }
}

class CrashReportService {
  final List<Map<String, dynamic>> _reportedCrashes = [];

  List<Map<String, dynamic>> get reportedCrashes => List.unmodifiable(_reportedCrashes);

  void recordCrash({
    required dynamic error,
    required StackTrace? stackTrace,
    Map<String, dynamic>? headers,
    dynamic requestBody,
    String? requestUrl,
    Map<String, dynamic>? extra,
  }) {
    final sanitizedRecord = <String, dynamic>{
      'error': CrashReportSanitizer.scrubString(error.toString()),
      'stackTrace': stackTrace != null
          ? CrashReportSanitizer.scrubString(stackTrace.toString())
          : null,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    if (requestUrl != null) {
      sanitizedRecord['url'] = CrashReportSanitizer.sanitizeUrl(requestUrl);
    }
    if (headers != null) {
      sanitizedRecord['headers'] = CrashReportSanitizer.sanitizeHeaders(headers);
    }
    if (requestBody != null) {
      sanitizedRecord['body'] = CrashReportSanitizer.sanitizeData(requestBody);
    }
    if (extra != null) {
      sanitizedRecord['extra'] = CrashReportSanitizer.sanitizeData(extra);
    }

    _reportedCrashes.add(sanitizedRecord);
  }

  void clearCrashes() {
    _reportedCrashes.clear();
  }
}

final crashReportServiceProvider = Provider<CrashReportService>((ref) {
  return CrashReportService();
});
